// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

//  ==========  Internal imports    ==========

import "../openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "../lib/CurrencyTransferLib.sol";

//  ==========  Features    ==========

import "../extension/ContractMetadata.sol";
import "../extension/PlatformFee.sol";
import "../extension/Royalty.sol";
import "../extension/PrimarySale.sol";
import "../extension/Ownable.sol";
import "../extension/DelayedReveal.sol";
import "../extension/PermissionsEnumerable.sol";

//  ========== New Features    ==========

import "../extension/LazyMintWithTier.sol";
import "../extension/SignatureActionUpgradeable.sol";

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
    MulticallUpgradeable,
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

    /// @dev Max bps in the thirdweb system.
    uint256 private constant MAX_BPS = 10_000;

    /**
     *  @dev Minting of NFTs on an ERC721A contract happens from a start tokenId (inclusive) to an end tokenId (non-inclusive).
     *
     *       Additionally, minting of tokenIds occurs in a strictly increasing order from `startTokenId()` (i.e. `0`)
     *       onwards: 0 < end_tokenId_1 < end_tokenId_2 < ... end_tokenId_n.
     *
     *       This array stores each end_tokenId_n for the n number of mints on this contract.
     */
    uint256[] private endIdsAtMint;

    /**
     *  @dev Each time NFTs are batch minted on this ERC721A contract, all NFTs in that batch belong to the same tier.
     *
     *       This is a mapping from `end_tokenId_n` -> the tier that tokenIds [end_tokenId_n-1, end_tokenId_n) belong to.
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

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Initiliazes the contract, like a constructor.
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
        uint256 metadataId = getMetadataId(_tokenId);

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    function contractType() external pure returns (bytes32) {
        return bytes32("TieredDrop");
    }

    function contractVersion() external pure returns (uint8) {
        return uint8(1);
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
    ) public override onlyRole(minterRole) returns (uint256 batchId) {
        if (_data.length > 0) {
            (bytes memory encryptedURI, bytes32 provenanceHash) = abi.decode(_data, (bytes, bytes32));
            if (encryptedURI.length != 0 && provenanceHash != "") {
                _setEncryptedData(nextTokenIdToLazyMint + _amount, _data);
            }
        }

        totalRemainingInTier[_tier] += _amount;

        uint256 startId = nextTokenIdToLazyMint;
        if (isTierEmpty(_tier)) {
            nextMetadataIdToMapFromTier[_tier] = startId;
        }

        return super.lazyMint(_amount, _baseURIForTokens, _tier, _data);
    }

    /// @dev Lets an account with `MINTER_ROLE` reveal the URI for a batch of 'delayed-reveal' NFTs.
    function reveal(uint256 _index, bytes calldata _key)
        external
        onlyRole(minterRole)
        returns (string memory revealedURI)
    {
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
    function claimWithSignature(GenericRequest calldata _req, bytes calldata _signature)
        external
        payable
        returns (address signer)
    {
        (
            string[] memory tiersInPriority,
            address to,
            address royaltyRecipient,
            uint256 royaltyBps,
            address primarySaleRecipient,
            uint256 quantity,
            uint256 pricePerToken,
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
        collectPriceOnClaim(primarySaleRecipient, quantity, currency, pricePerToken);

        // Set royalties, if applicable.
        if (royaltyRecipient != address(0) && royaltyBps != 0) {
            _setupRoyaltyInfoForToken(tokenIdToMint, royaltyRecipient, royaltyBps);
        }

        // Mint tokens.
        transferTokensOnClaim(to, quantity, tiersInPriority);

        emit RequestExecuted(_msgSender(), signer, _req);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/
    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal {
        if (_pricePerToken == 0) {
            return;
        }

        address saleRecipient = _primarySaleRecipient == address(0) ? primarySaleRecipient() : _primarySaleRecipient;

        uint256 totalPrice = _quantityToClaim * _pricePerToken;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            if (msg.value != totalPrice) {
                revert("!Price");
            }
        }

        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), saleRecipient, totalPrice);
    }

    /// @dev Transfers the NFTs being claimed.
    function transferTokensOnClaim(
        address _to,
        uint256 _totalQuantityBeingClaimed,
        string[] memory _tiers
    ) internal {
        uint256 startTokenIdToMint = _currentIndex;

        uint256 startIdToMap = startTokenIdToMint;
        uint256 remaningToDistribute = _totalQuantityBeingClaimed;

        for (uint256 i = 0; i < _tiers.length; i += 1) {
            string memory tier = _tiers[i];

            (uint256 qtyFulfilled, uint256 qtyUnfulfilled) = _getQuantityFulfilledByTier(tier, remaningToDistribute);

            _mapTokensToTier(tier, startIdToMap, qtyFulfilled);

            totalRemainingInTier[tier] -= qtyFulfilled;

            if (qtyUnfulfilled > 0) {
                startIdToMap += qtyFulfilled;
                remaningToDistribute = qtyUnfulfilled;
            } else {
                break;
            }
        }

        _safeMint(_to, _totalQuantityBeingClaimed);
    }

    function _mapTokensToTier(
        string memory _tier,
        uint256 _startIdToMap,
        uint256 _quantity
    ) private {
        uint256 proxyStartId = nextMetadataIdToMapFromTier[_tier];
        uint256 proxyEndId = proxyStartId + _quantity;

        uint256 endTokenId = _startIdToMap + _quantity;

        endIdsAtMint.push(endTokenId);
        tierAtEndId[endTokenId] = _tier;
        proxyTokenRange[endTokenId] = TokenRange(proxyStartId, proxyEndId);

        nextMetadataIdToMapFromTier[_tier] += _quantity;
    }

    function _getQuantityFulfilledByTier(string memory _tier, uint256 _quantity)
        private
        view
        returns (uint256, uint256)
    {
        uint256 total = totalRemainingInTier[_tier];

        if (total > _quantity) {
            return (total - _quantity, 0);
        } else {
            return (total, _quantity - total);
        }
    }

    function getMintInstances() external view returns (uint256) {
        return endIdsAtMint.length;
    }

    function getTokensInTier(
        string memory _tier,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (TokenRange[] memory ranges) {
        uint256 len = endIdsAtMint.length;

        require(startIndex < endIndex && endIndex <= len, "TieredDrop: invalid indices.");

        uint256[] memory endIds = endIdsAtMint;
        uint256 numOfRanges;

        for (uint256 i = startIndex; i < endIndex; i += 1) {
            if (keccak256(bytes(tierAtEndId[endIds[i]])) == keccak256(bytes(_tier))) {
                numOfRanges += 1;
            }
        }

        ranges = new TokenRange[](numOfRanges);
        for (uint256 j = startIndex; j < endIndex; j += 1) {
            if (keccak256(bytes(tierAtEndId[endIds[j]])) == keccak256(bytes(_tier))) {
                uint256 start = startIndex == 0 ? 0 : endIds[startIndex - 1];
                ranges[j] = TokenRange(start, endIds[j]);
            }
        }
    }

    function getMetadataId(uint256 _tokenId) public view returns (uint256) {
        uint256[] memory endIds = endIdsAtMint;
        uint256 len = endIds.length;

        for (uint256 i = 0; i < len; i += 1) {
            if (_tokenId < endIds[i]) {
                uint256 targetEndId = endIds[i];
                uint256 diff = targetEndId - _tokenId;

                TokenRange memory range = proxyTokenRange[targetEndId];

                return range.endIdNonInclusive - diff;
            }
        }

        revert("Metadata ID not found for token.");
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
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function totalMinted() external view returns (uint256) {
        unchecked {
            return _currentIndex - _startTokenId();
        }
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
                revert("!Transfer-Role");
            }
        }
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
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
