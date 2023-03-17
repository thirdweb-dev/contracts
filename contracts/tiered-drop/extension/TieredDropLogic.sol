// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import { TieredDropStorage } from "./TieredDropStorage.sol";
import { ERC721AStorage } from "../../dynamic-contracts/eip/ERC721AUpgradeable.sol";

import "../../lib/TWStrings.sol";
import "../../lib/CurrencyTransferLib.sol";

import { IERC2981 } from "../../eip/interface/IERC2981.sol";
import { Context, ERC721AUpgradeable } from "../../dynamic-contracts/eip/ERC721AUpgradeable.sol";

import { IERC2771Context } from "../../extension/interface/IERC2771Context.sol";

import { ERC2771ContextUpgradeable } from "../../dynamic-contracts/extension/ERC2771ContextUpgradeable.sol";
import { DelayedReveal } from "../../dynamic-contracts/extension/DelayedReveal.sol";
import { PrimarySale } from "../../dynamic-contracts/extension/PrimarySale.sol";
import { Royalty, IERC165 } from "../../dynamic-contracts/extension/Royalty.sol";
import { LazyMintWithTier } from "../../dynamic-contracts/extension/LazyMintWithTier.sol";
import { ContractMetadata } from "../../dynamic-contracts/extension/ContractMetadata.sol";
import { Ownable } from "../../dynamic-contracts/extension/Ownable.sol";
import { SignatureActionUpgradeable } from "../../dynamic-contracts/extension/SignatureActionUpgradeable.sol";
import { DefaultOperatorFiltererUpgradeable } from "../../dynamic-contracts/extension/DefaultOperatorFiltererUpgradeable.sol";
import { PermissionsStorage } from "../../dynamic-contracts/extension/Permissions.sol";

contract TieredDropLogic is
    Royalty,
    PrimarySale,
    DelayedReveal,
    LazyMintWithTier,
    ContractMetadata,
    Ownable,
    SignatureActionUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    ERC2771ContextUpgradeable,
    ERC721AUpgradeable
{
    using TWStrings for uint256;

    /*///////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/

    /// @dev Default admin role for all roles. Only accounts with this role can grant/revoke other roles.
    bytes32 private constant DEFAULT_ADMIN_ROLE = 0x00;
    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s and lazy mint tokens.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @dev Only transfers initiated by operator role hodlers are valid, when operator-initated transfers are restricted.
    bytes32 private constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || type(IERC2981).interfaceId == interfaceId;
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
        TieredDropStorage.Data storage data = TieredDropStorage.tieredDropStorage();

        uint256 nextId = nextTokenIdToLazyMint();
        if (_data.length > 0) {
            (bytes memory encryptedURI, bytes32 provenanceHash) = abi.decode(_data, (bytes, bytes32));
            if (encryptedURI.length != 0 && provenanceHash != "") {
                _setEncryptedData(nextId + _amount, _data);
            }
        }

        data.totalRemainingInTier[_tier] += _amount;

        uint256 startId = nextId;
        if (isTierEmpty(_tier) || data.nextMetadataIdToMapFromTier[_tier] == type(uint256).max) {
            data.nextMetadataIdToMapFromTier[_tier] = startId;
        }

        return super.lazyMint(_amount, _baseURIForTokens, _tier, _data);
    }

    /// @dev Lets an account with `MINTER_ROLE` reveal the URI for a batch of 'delayed-reveal' NFTs.
    function reveal(uint256 _index, bytes calldata _key) external returns (string memory revealedURI) {
        require(_hasRole(MINTER_ROLE, _msgSender()), "not minter.");

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
        ERC721AStorage.Data storage data = ERC721AStorage.erc721AStorage();

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

        uint256 tokenIdToMint = data._currentIndex;
        if (tokenIdToMint + quantity > nextTokenIdToLazyMint()) {
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
    function collectPriceOnClaim(
        address _primarySaleRecipient,
        address _currency,
        uint256 _totalPrice
    ) internal {
        if (_totalPrice == 0) {
            return;
        }

        address saleRecipient = _primarySaleRecipient == address(0) ? primarySaleRecipient() : _primarySaleRecipient;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            if (msg.value != _totalPrice) {
                revert("!Price");
            }
        }

        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), saleRecipient, _totalPrice);
    }

    /// @dev Transfers the NFTs being claimed.
    function transferTokensOnClaim(
        address _to,
        uint256 _totalQuantityBeingClaimed,
        string[] memory _tiers
    ) internal {
        TieredDropStorage.Data storage data = TieredDropStorage.tieredDropStorage();
        ERC721AStorage.Data storage dataERC721A = ERC721AStorage.erc721AStorage();

        uint256 startTokenIdToMint = dataERC721A._currentIndex;

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

            data.totalRemainingInTier[tier] -= qtyFulfilled;
            data.totalsForTier[keccak256(abi.encodePacked(tier, "minted"))] += qtyFulfilled;

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
    function _mapTokensToTier(
        string memory _tier,
        uint256 _startIdToMap,
        uint256 _quantity
    ) private {
        TieredDropStorage.Data storage data = TieredDropStorage.tieredDropStorage();

        uint256 nextIdFromTier = data.nextMetadataIdToMapFromTier[_tier];
        uint256 startTokenId = _startIdToMap;

        TokenRange[] memory tokensInTier = tokensInTier(_tier);
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

                data.endIdsAtMint[data.lengthEndIdsAtMint] = endTokenId;
                data.lengthEndIdsAtMint += 1;

                data.tierAtEndId[endTokenId] = _tier;
                data.proxyTokenRange[endTokenId] = TokenRange(proxyStartId, proxyEndId);

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
                data.nextMetadataIdToMapFromTier[_tier] = nextIdFromTier;
                break;
            }
        }
    }

    /// @dev Returns how much of the total-quantity-to-distribute can come from the given tier.
    function _getQuantityFulfilledByTier(string memory _tier, uint256 _quantity)
        private
        view
        returns (uint256 fulfilled)
    {
        TieredDropStorage.Data storage data = TieredDropStorage.tieredDropStorage();

        uint256 total = data.totalRemainingInTier[_tier];

        if (total >= _quantity) {
            fulfilled = _quantity;
        } else {
            fulfilled = total;
        }
    }

    /// @dev Returns the tier that the given token is associated with.
    function getTierForToken(uint256 _tokenId) external view returns (string memory) {
        TieredDropStorage.Data storage data = TieredDropStorage.tieredDropStorage();

        uint256 len = data.lengthEndIdsAtMint;

        for (uint256 i = 0; i < len; i += 1) {
            uint256 endId = data.endIdsAtMint[i];

            if (_tokenId < endId) {
                return data.tierAtEndId[endId];
            }
        }

        revert("!Tier");
    }

    /// @dev Returns the max `endIndex` that can be used with getTokensInTier.
    function getTokensInTierLen() external view returns (uint256) {
        TieredDropStorage.Data storage data = TieredDropStorage.tieredDropStorage();
        return data.lengthEndIdsAtMint;
    }

    /// @dev Returns all tokenIds that belong to the given tier.
    function getTokensInTier(
        string memory _tier,
        uint256 _startIdx,
        uint256 _endIdx
    ) external view returns (TokenRange[] memory ranges) {
        TieredDropStorage.Data storage data = TieredDropStorage.tieredDropStorage();

        uint256 len = data.lengthEndIdsAtMint;

        require(_startIdx < _endIdx && _endIdx <= len, "TieredDrop: invalid indices.");

        uint256 numOfRangesForTier = 0;
        bytes32 hashOfTier = keccak256(abi.encodePacked(_tier));

        for (uint256 i = _startIdx; i < _endIdx; i += 1) {
            bytes32 hashOfStoredTier = keccak256(abi.encodePacked(data.tierAtEndId[data.endIdsAtMint[i]]));

            if (hashOfStoredTier == hashOfTier) {
                numOfRangesForTier += 1;
            }
        }

        ranges = new TokenRange[](numOfRangesForTier);
        uint256 idx = 0;

        for (uint256 i = _startIdx; i < _endIdx; i += 1) {
            bytes32 hashOfStoredTier = keccak256(abi.encodePacked(data.tierAtEndId[data.endIdsAtMint[i]]));

            if (hashOfStoredTier == hashOfTier) {
                uint256 end = data.endIdsAtMint[i];

                uint256 start = 0;
                if (i > 0) {
                    start = data.endIdsAtMint[i - 1];
                }

                ranges[idx] = TokenRange(start, end);
                idx += 1;
            }
        }
    }

    /// @dev Returns the metadata ID for the given tokenID.
    function _getMetadataId(uint256 _tokenId) private view returns (uint256) {
        TieredDropStorage.Data storage data = TieredDropStorage.tieredDropStorage();

        uint256 len = data.lengthEndIdsAtMint;

        for (uint256 i = 0; i < len; i += 1) {
            if (_tokenId < data.endIdsAtMint[i]) {
                uint256 targetEndId = data.endIdsAtMint[i];
                uint256 diff = targetEndId - _tokenId;

                TokenRange memory range = data.proxyTokenRange[targetEndId];

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
        TieredDropStorage.Data storage data = TieredDropStorage.tieredDropStorage();

        bytes32 bytesRandom = data.tokenIdOffset[_batchId];
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
        fairMetadataId = (_metadataId + offset) % batchSize;
    }

    /// @dev Scrambles tokenId offset for a given batchId.
    function _scrambleOffset(uint256 _batchId, bytes calldata _seed) private {
        TieredDropStorage.Data storage data = TieredDropStorage.tieredDropStorage();
        data.tokenIdOffset[_batchId] = keccak256(abi.encodePacked(_seed, block.timestamp, blockhash(block.number - 1)));
    }

    /// @dev Returns whether a given address is authorized to sign mint requests.
    function _isAuthorizedSigner(address _signer) internal view override returns (bool) {
        return _hasRole(MINTER_ROLE, _signer);
    }

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function _canLazyMint() internal view virtual override returns (bool) {
        return _hasRole(MINTER_ROLE, _msgSender());
    }

    /// @dev Returns whether the operator restriction can be set within the given execution context.
    function _canSetOperatorRestriction() internal virtual override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether owner can be set in the given execution context.
    function _canSetOwner() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function totalMinted() external view returns (uint256) {
        ERC721AStorage.Data storage data = ERC721AStorage.erc721AStorage();
        unchecked {
            return data._currentIndex - _startTokenId();
        }
    }

    /// @dev Returns the total number of tokens minted from the given tier.
    function totalMintedInTier(string memory _tier) external view returns (uint256) {
        TieredDropStorage.Data storage data = TieredDropStorage.tieredDropStorage();
        return data.totalsForTier[keccak256(abi.encodePacked(_tier, "minted"))];
    }

    /// @dev The tokenId of the next NFT that will be minted / lazy minted.
    function nextTokenIdToMint() external view returns (uint256) {
        return nextTokenIdToLazyMint();
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
        if (!_hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            if (!_hasRole(TRANSFER_ROLE, from) && !_hasRole(TRANSFER_ROLE, to)) {
                revert("!TRANSFER");
            }
        }
    }

    /// @dev See {ERC721-isApprovedForAll}.
    function getApproved(uint256 tokenId) public view override returns (address) {
        address operator = super.getApproved(tokenId);
        bool operatorRoleApproval = _hasRoleWithSwitch(OPERATOR_ROLE, operator);

        return operatorRoleApproval ? operator : address(0);
    }

    /// @dev See {ERC721-isApprovedForAll}.
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        bool operatorRoleApproval = true;
        if (account != operator) {
            operatorRoleApproval = _hasRoleWithSwitch(OPERATOR_ROLE, operator);
        }
        return operatorRoleApproval && super.isApprovedForAll(account, operator);
    }

    /// @dev See {ERC721-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev See {ERC721-approve}.
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /// @dev See {ERC721-_transferFrom}.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /// @dev See {ERC721-_safeTransferFrom}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @dev See {ERC721-_safeTransferFrom}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _hasRole(bytes32 role, address addr) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        return data._hasRole[role][addr];
    }

    function _hasRoleWithSwitch(bytes32 role, address account) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        if (!data._hasRole[role][address(0)]) {
            return data._hasRole[role][account];
        }

        return true;
    }

    function _msgSender() internal view override(Context, ERC2771ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }
}
