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

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

import "../../../eip/queryable/ERC721AQueryableUpgradeable.sol";

//  ==========  Internal imports    ==========

import "../../../external-deps/openzeppelin/metatx/ERC2771ContextUpgradeable.sol";
import "../../../lib/CurrencyTransferLib.sol";

//  ==========  Features    ==========

import "../../../extension/Multicall.sol";
import "../../../extension/upgradeable/ContractMetadata.sol";
import "../../../extension/upgradeable/Royalty.sol";
import "../../../extension/upgradeable/PrimarySale.sol";
import "../../../extension/upgradeable/Ownable.sol";
import "../../../extension/upgradeable/Permissions.sol";
import "../../../extension/upgradeable/Drop.sol";
import "../../../extension/upgradeable/SharedMetadataBatch.sol";
import { RulesEngine } from "../../../extension/upgradeable/RulesEngine.sol";

// OpenSea operator filter
import "../../../extension/DefaultOperatorFiltererUpgradeable.sol";

contract EvolvingNFTLogic is
    ContractMetadata,
    Royalty,
    PrimarySale,
    Ownable,
    SharedMetadataBatch,
    Drop,
    ERC2771ContextUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    ERC721AQueryableUpgradeable
{
    using StringsUpgradeable for uint256;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev Default admin role for all roles. Only accounts with this role can grant/revoke other roles.
    bytes32 private constant DEFAULT_ADMIN_ROLE = 0x00;
    /// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        if (!_exists(_tokenId)) {
            revert("!ID");
        }

        // Get score
        address owner = ownerOf(_tokenId);
        uint256 score = 0;

        address engine = RulesEngine(address(this)).getRulesEngineOverride();
        if (engine != address(0)) {
            score = RulesEngine(engine).getScore(owner);
        } else {
            score = RulesEngine(address(this)).getScore(owner);
        }

        // Get the target ID i.e. `start` of the range that the score falls into.
        bytes32[] memory ids = _sharedMetadataBatchStorage().ids.values();
        bytes32 targetId = 0;
        uint256 check = 0;

        for (uint256 i = 0; i < ids.length; i += 1) {
            uint256 id = uint256(ids[i]);

            if (id <= score && id >= check) {
                targetId = ids[i];
                check = id;
            }
        }
        return _getURIFromSharedMetadata(targetId, _tokenId);
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    /// @dev The start token ID for the contract.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function startTokenId() public pure returns (uint256) {
        return _startTokenId();
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function _collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal override {
        if (_pricePerToken == 0) {
            require(msg.value == 0, "!Value");
            return;
        }

        uint256 totalPrice = _quantityToClaim * _pricePerToken;

        bool validMsgValue;
        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            validMsgValue = msg.value == totalPrice;
        } else {
            validMsgValue = msg.value == 0;
        }
        require(validMsgValue, "!V");

        address saleRecipient = _primarySaleRecipient == address(0) ? primarySaleRecipient() : _primarySaleRecipient;

        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), saleRecipient, totalPrice);
    }

    /// @dev Transfers the NFTs being claimed.
    function _transferTokensOnClaim(address _to, uint256 _quantityBeingClaimed)
        internal
        override
        returns (uint256 startTokenId_)
    {
        startTokenId_ = _nextTokenId();
        _safeMint(_to, _quantityBeingClaimed);
    }

    /// @dev Checks whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether owner can be set in the given execution context.
    function _canSetOwner() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetClaimConditions() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Returns whether shared metadata can be set in the given execution context.
    function _canSetSharedMetadata() internal view virtual override returns (bool) {
        return _hasRole(MINTER_ROLE, _msgSender());
    }

    /// @dev Returns whether operator restriction can be set in the given execution context.
    function _canSetOperatorRestriction() internal virtual override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether an account has a particular role.
    function _hasRole(bytes32 _role, address _account) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.data();
        return data._hasRole[_role][_account];
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function totalMinted() external view returns (uint256) {
        unchecked {
            return _nextTokenId() - _startTokenId();
        }
    }

    /// @dev The tokenId of the next NFT that will be minted / lazy minted.
    function nextTokenIdToMint() external view returns (uint256) {
        return _nextTokenId();
    }

    /// @dev The next token ID of the NFT that can be claimed.
    function nextTokenIdToClaim() external view returns (uint256) {
        return _nextTokenId();
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
        uint256 startTokenId_,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId_, quantity);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!_hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            if (!_hasRole(TRANSFER_ROLE, from) && !_hasRole(TRANSFER_ROLE, to)) {
                revert("!T");
            }
        }
    }

    /// @dev See {ERC721-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev See {ERC721-approve}.
    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /// @dev See {ERC721-_transferFrom}.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /// @dev See {ERC721-_safeTransferFrom}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @dev See {ERC721-_safeTransferFrom}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _dropMsgSender() internal view virtual override returns (address) {
        return _msgSender();
    }

    function _msgSender() internal view virtual override returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }
}
