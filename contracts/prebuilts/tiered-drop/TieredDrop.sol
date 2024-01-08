// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

//  ==========  External imports    ==========

import "../../extension/Multicall.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

//  ==========  Internal imports    ==========

import "../../external-deps/openzeppelin/metatx/ERC2771ContextUpgradeable.sol";
import "../../lib/CurrencyTransferLib.sol";

//  ==========  Features    ==========

import "../../extension/ContractMetadata.sol";
import "../../extension/PlatformFee.sol";
import "../../extension/Royalty.sol";
import "../../extension/PrimarySale.sol";
import "../../extension/Ownable.sol";
import "../../extension/DelayedReveal.sol";
import "../../extension/PermissionsEnumerable.sol";

//  ========== New Features    ==========

import "../../extension/LazyMintWithTier.sol";
import "../../extension/SignatureActionUpgradeable.sol";

contract TieredDrop is
    Initializable,
    ContractMetadata,
    Royalty,
    PrimarySale,
    Ownable,
    DelayedReveal,
    LazyMintWithTier,
    PermissionsEnumerable,
    SignatureActionUpgradeable,
    ERC2771ContextUpgradeable,
    Multicall,
    ERC721AUpgradeable
{
    using StringsUpgradeable for uint256;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private transferRole;
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s and lazy mint tokens.
    bytes32 private minterRole;

    /**
     *  @dev Conceptually, tokens are minted on this contract one-batch-of-a-tier at a time. Each batch is comprised of
     *       a given range of tokenIds [startId, endId).
     *
     *       This array stores each such endId, in chronological order of minting.
     */
    uint256 private lengthEndIdsAtMint;
    mapping(uint256 => uint256) private endIdsAtMint;

    /**
     *  @dev Conceptually, tokens are minted on this contract one-batch-of-a-tier at a time. Each batch is comprised of
     *       a given range of tokenIds [startId, endId).
     *
     *       This is a mapping from such an `endId` -> the tier that tokenIds [startId, endId) belong to.
     *       Together with `endIdsAtMint`, this mapping is used to return the tokenIds that belong to a given tier.
     */
    mapping(uint256 => string) private tierAtEndId;

    /**
     *  @dev This contract lets an admin lazy mint batches of metadata at once, for a given tier. E.g. an admin may lazy mint
     *       the metadata of 5000 tokens that will actually be minted in the future.
     *
     *       Lazy minting of NFT metafata happens from a start metadata ID (inclusive) to an end metadata ID (non-inclusive),
     *       where the lazy minted metadata lives at `providedBaseURI/${metadataId}` for each unit metadata.
     *
     *       At the time of actual minting, the minter specifies the tier of NFTs they're minting. So, the order in which lazy minted
     *       metadata for a tier is assigned integer IDs may differ from the actual tokenIds minted for a tier.
     *
     *       This is a mapping from an actually minted end tokenId -> the range of lazy minted metadata that now belongs
     *       to NFTs of [start tokenId, end tokenid).
     */
    mapping(uint256 => TokenRange) private proxyTokenRange;

    /// @dev Mapping from tier -> the metadata ID up till which metadata IDs have been mapped to minted NFTs' tokenIds.
    mapping(string => uint256) private nextMetadataIdToMapFromTier;

    /// @dev Mapping from tier -> how many units of lazy minted metadata have not yet been mapped to minted NFTs' tokenIds.
    mapping(string => uint256) private totalRemainingInTier;

    /// @dev Mapping from batchId => tokenId offset for that batchId.
    mapping(uint256 => bytes32) private tokenIdOffset;

    /// @dev Mapping from hash(tier, "minted") -> total minted in tier.
    mapping(bytes32 => uint256) private totalsForTier;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when tokens are claimed via `claimWithSignature`.
    event TokensClaimed(
        address indexed claimer,
        address indexed receiver,
        uint256 startTokenId,
        uint256 quantityClaimed,
        string[] tiersInPriority
    );

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Initializes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint16 _royaltyBps
    ) external initializer {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        bytes32 _minterRole = keccak256("MINTER_ROLE");

        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init(_trustedForwarders);
        __ERC721A_init(_name, _symbol);
        __SignatureAction_init();

        _setupContractURI(_contractURI);
        _setupOwner(_defaultAdmin);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(_minterRole, _defaultAdmin);
        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));

        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupPrimarySaleRecipient(_saleRecipient);

        transferRole = _transferRole;
        minterRole = _minterRole;
    }

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        // Retrieve metadata ID for token.
        uint256 metadataId = _getMetadataId(_tokenId);

        // Use metadata ID to return token metadata.
        (uint256 batchId, uint256 index) = _getBatchId(metadataId);
        string memory batchUri = _getBaseURI(metadataId);

        if (isEncryptedBatch(batchId)) {
            return string(abi.encodePacked(batchUri, "0"));
        } else {
            uint256 fairMetadataId = _getFairMetadataId(metadataId, batchId, index);
            return string(abi.encodePacked(batchUri, fairMetadataId.toString()));
        }
    }

    /// @dev See ERC 165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721AUpgradeable, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    /*///////////////////////////////////////////////////////////////
                    Lazy minting + delayed-reveal logic
    //////////////////////////////////////////////////////////////*

    /**
     *  @dev Lets an account with `MINTER_ROLE` lazy mint 'n' NFTs.
     *       The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.
     */
    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        string calldata _tier,
        bytes calldata _data
    ) public override returns (uint256 batchId) {
        if (_data.length > 0) {
            (bytes memory encryptedURI, bytes32 provenanceHash) = abi.decode(_data, (bytes, bytes32));
            if (encryptedURI.length != 0 && provenanceHash != "") {
                _setEncryptedData(nextTokenIdToLazyMint + _amount, _data);
            }
        }

        totalRemainingInTier[_tier] += _amount;

        uint256 startId = nextTokenIdToLazyMint;
        if (isTierEmpty(_tier) || nextMetadataIdToMapFromTier[_tier] == type(uint256).max) {
            nextMetadataIdToMapFromTier[_tier] = startId;
        }

        return super.lazyMint(_amount, _baseURIForTokens, _tier, _data);
    }

    /// @dev Lets an account with `MINTER_ROLE` reveal the URI for a batch of 'delayed-reveal' NFTs.
    function reveal(
        uint256 _index,
        bytes calldata _key
    ) external onlyRole(minterRole) returns (string memory revealedURI) {
        uint256 batchId = getBatchIdAtIndex(_index);
        revealedURI = getRevealURI(batchId, _key);

        _setEncryptedData(batchId, "");
        _setBaseURI(batchId, revealedURI);

        _scrambleOffset(batchId, _key);

        emit TokenURIRevealed(_index, revealedURI);
    }

    /*///////////////////////////////////////////////////////////////
                    Claiming lazy minted tokens logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Claim lazy minted tokens via signature.
    function claimWithSignature(
        GenericRequest calldata _req,
        bytes calldata _signature
    ) external payable returns (address signer) {
        (
            string[] memory tiersInPriority,
            address to,
            address royaltyRecipient,
            uint256 royaltyBps,
            address primarySaleRecipient,
            uint256 quantity,
            uint256 totalPrice,
            address currency
        ) = abi.decode(_req.data, (string[], address, address, uint256, address, uint256, uint256, address));

        if (quantity == 0) {
            revert("0 qty");
        }

        uint256 tokenIdToMint = _currentIndex;
        if (tokenIdToMint + quantity > nextTokenIdToLazyMint) {
            revert("!Tokens");
        }

        // Verify and process payload.
        signer = _processRequest(_req, _signature);

        // Collect price
        collectPriceOnClaim(primarySaleRecipient, currency, totalPrice);

        // Set royalties, if applicable.
        if (royaltyRecipient != address(0) && royaltyBps != 0) {
            _setupRoyaltyInfoForToken(tokenIdToMint, royaltyRecipient, royaltyBps);
        }

        // Mint tokens.
        transferTokensOnClaim(to, quantity, tiersInPriority);

        emit TokensClaimed(_msgSender(), to, tokenIdToMint, quantity, tiersInPriority);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/
    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectPriceOnClaim(address _primarySaleRecipient, address _currency, uint256 _totalPrice) internal {
        if (_totalPrice == 0) {
            require(msg.value == 0, "!Value");
            return;
        }

        address saleRecipient = _primarySaleRecipient == address(0) ? primarySaleRecipient() : _primarySaleRecipient;

        bool validMsgValue;
        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            validMsgValue = msg.value == _totalPrice;
        } else {
            validMsgValue = msg.value == 0;
        }
        require(validMsgValue, "Invalid msg value");

        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), saleRecipient, _totalPrice);
    }

    /// @dev Transfers the NFTs being claimed.
    function transferTokensOnClaim(address _to, uint256 _totalQuantityBeingClaimed, string[] memory _tiers) internal {
        uint256 startTokenIdToMint = _currentIndex;

        uint256 startIdToMap = startTokenIdToMint;
        uint256 remaningToDistribute = _totalQuantityBeingClaimed;

        for (uint256 i = 0; i < _tiers.length; i += 1) {
            string memory tier = _tiers[i];

            uint256 qtyFulfilled = _getQuantityFulfilledByTier(tier, remaningToDistribute);

            if (qtyFulfilled == 0) {
                continue;
            }

            remaningToDistribute -= qtyFulfilled;

            _mapTokensToTier(tier, startIdToMap, qtyFulfilled);

            totalRemainingInTier[tier] -= qtyFulfilled;
            totalsForTier[keccak256(abi.encodePacked(tier, "minted"))] += qtyFulfilled;

            if (remaningToDistribute > 0) {
                startIdToMap += qtyFulfilled;
            } else {
                break;
            }
        }

        require(remaningToDistribute == 0, "Insufficient tokens in tiers.");

        _safeMint(_to, _totalQuantityBeingClaimed);
    }

    /// @dev Maps lazy minted metadata to NFT tokenIds.
    function _mapTokensToTier(string memory _tier, uint256 _startIdToMap, uint256 _quantity) private {
        uint256 nextIdFromTier = nextMetadataIdToMapFromTier[_tier];
        uint256 startTokenId = _startIdToMap;

        TokenRange[] memory tokensInTier = tokensInTier[_tier];
        uint256 len = tokensInTier.length;

        uint256 qtyRemaining = _quantity;

        for (uint256 i = 0; i < len; i += 1) {
            TokenRange memory range = tokensInTier[i];
            uint256 gap = 0;

            if (range.startIdInclusive <= nextIdFromTier && nextIdFromTier < range.endIdNonInclusive) {
                uint256 proxyStartId = nextIdFromTier;
                uint256 proxyEndId = proxyStartId + qtyRemaining <= range.endIdNonInclusive
                    ? proxyStartId + qtyRemaining
                    : range.endIdNonInclusive;

                gap = proxyEndId - proxyStartId;

                uint256 endTokenId = startTokenId + gap;

                endIdsAtMint[lengthEndIdsAtMint] = endTokenId;
                lengthEndIdsAtMint += 1;

                tierAtEndId[endTokenId] = _tier;
                proxyTokenRange[endTokenId] = TokenRange(proxyStartId, proxyEndId);

                startTokenId += gap;
                qtyRemaining -= gap;

                if (nextIdFromTier + gap < range.endIdNonInclusive) {
                    nextIdFromTier += gap;
                } else if (i < (len - 1)) {
                    nextIdFromTier = tokensInTier[i + 1].startIdInclusive;
                } else {
                    nextIdFromTier = type(uint256).max;
                }
            }

            if (qtyRemaining == 0) {
                nextMetadataIdToMapFromTier[_tier] = nextIdFromTier;
                break;
            }
        }
    }

    /// @dev Returns how much of the total-quantity-to-distribute can come from the given tier.
    function _getQuantityFulfilledByTier(
        string memory _tier,
        uint256 _quantity
    ) private view returns (uint256 fulfilled) {
        uint256 total = totalRemainingInTier[_tier];

        if (total >= _quantity) {
            fulfilled = _quantity;
        } else {
            fulfilled = total;
        }
    }

    /// @dev Returns the tier that the given token is associated with.
    function getTierForToken(uint256 _tokenId) external view returns (string memory) {
        uint256 len = lengthEndIdsAtMint;

        for (uint256 i = 0; i < len; i += 1) {
            uint256 endId = endIdsAtMint[i];

            if (_tokenId < endId) {
                return tierAtEndId[endId];
            }
        }

        revert("!Tier");
    }

    /// @dev Returns the max `endIndex` that can be used with getTokensInTier.
    function getTokensInTierLen() external view returns (uint256) {
        return lengthEndIdsAtMint;
    }

    /// @dev Returns all tokenIds that belong to the given tier.
    function getTokensInTier(
        string memory _tier,
        uint256 _startIdx,
        uint256 _endIdx
    ) external view returns (TokenRange[] memory ranges) {
        uint256 len = lengthEndIdsAtMint;

        require(_startIdx < _endIdx && _endIdx <= len, "TieredDrop: invalid indices.");

        uint256 numOfRangesForTier = 0;
        bytes32 hashOfTier = keccak256(abi.encodePacked(_tier));

        for (uint256 i = _startIdx; i < _endIdx; i += 1) {
            bytes32 hashOfStoredTier = keccak256(abi.encodePacked(tierAtEndId[endIdsAtMint[i]]));

            if (hashOfStoredTier == hashOfTier) {
                numOfRangesForTier += 1;
            }
        }

        ranges = new TokenRange[](numOfRangesForTier);
        uint256 idx = 0;

        for (uint256 i = _startIdx; i < _endIdx; i += 1) {
            bytes32 hashOfStoredTier = keccak256(abi.encodePacked(tierAtEndId[endIdsAtMint[i]]));

            if (hashOfStoredTier == hashOfTier) {
                uint256 end = endIdsAtMint[i];

                uint256 start = 0;
                if (i > 0) {
                    start = endIdsAtMint[i - 1];
                }

                ranges[idx] = TokenRange(start, end);
                idx += 1;
            }
        }
    }

    /// @dev Returns the metadata ID for the given tokenID.
    function _getMetadataId(uint256 _tokenId) private view returns (uint256) {
        uint256 len = lengthEndIdsAtMint;

        for (uint256 i = 0; i < len; i += 1) {
            if (_tokenId < endIdsAtMint[i]) {
                uint256 targetEndId = endIdsAtMint[i];
                uint256 diff = targetEndId - _tokenId;

                TokenRange memory range = proxyTokenRange[targetEndId];

                return range.endIdNonInclusive - diff;
            }
        }

        revert("!Metadata-ID");
    }

    /// @dev Returns the fair metadata ID for a given tokenId.
    function _getFairMetadataId(
        uint256 _metadataId,
        uint256 _batchId,
        uint256 _indexOfBatchId
    ) private view returns (uint256 fairMetadataId) {
        bytes32 bytesRandom = tokenIdOffset[_batchId];
        if (bytesRandom == bytes32(0)) {
            return _metadataId;
        }

        uint256 randomness = uint256(bytesRandom);
        uint256 prevBatchId;
        if (_indexOfBatchId > 0) {
            prevBatchId = getBatchIdAtIndex(_indexOfBatchId - 1);
        }

        uint256 batchSize = _batchId - prevBatchId;
        uint256 offset = randomness % batchSize;
        fairMetadataId = prevBatchId + ((_metadataId + offset) % batchSize);
    }

    /// @dev Scrambles tokenId offset for a given batchId.
    function _scrambleOffset(uint256 _batchId, bytes calldata _seed) private {
        tokenIdOffset[_batchId] = keccak256(abi.encodePacked(_seed, block.timestamp, blockhash(block.number - 1)));
    }

    /// @dev Returns whether a given address is authorized to sign mint requests.
    function _isAuthorizedSigner(address _signer) internal view override returns (bool) {
        return hasRole(minterRole, _signer);
    }

    /// @dev Checks whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether owner can be set in the given execution context.
    function _canSetOwner() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function _canLazyMint() internal view virtual override returns (bool) {
        return hasRole(minterRole, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function totalMinted() external view returns (uint256) {
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /// @dev Returns the total number of tokens minted from the given tier.
    function totalMintedInTier(string memory _tier) external view returns (uint256) {
        return totalsForTier[keccak256(abi.encodePacked(_tier, "minted"))];
    }

    /// @dev The tokenId of the next NFT that will be minted / lazy minted.
    function nextTokenIdToMint() external view returns (uint256) {
        return nextTokenIdToLazyMint;
    }

    /// @dev Burns `tokenId`. See {ERC721-_burn}.
    function burn(uint256 tokenId) external virtual {
        // note: ERC721AUpgradeable's `_burn(uint256,bool)` internally checks for token approvals.
        _burn(tokenId, true);
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(transferRole, address(0)) && from != address(0) && to != address(0)) {
            if (!hasRole(transferRole, from) && !hasRole(transferRole, to)) {
                revert("!TRANSFER");
            }
        }
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable, Multicall)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}
