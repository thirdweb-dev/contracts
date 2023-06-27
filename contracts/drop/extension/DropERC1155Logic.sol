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

import { DropERC1155Storage } from "./DropERC1155Storage.sol";

import "../../lib/TWStrings.sol";
import "../../lib/CurrencyTransferLib.sol";

import { IERC2981 } from "../../eip/interface/IERC2981.sol";
import { Context, ERC1155Upgradeable, ERC1155Storage } from "../../dynamic-contracts/eip/ERC1155Upgradeable.sol";

import { IERC2771Context } from "../../extension/interface/IERC2771Context.sol";

import { IERC1155 } from "../../eip/interface/IERC1155.sol";
import { IERC1155Metadata } from "../../eip/interface/IERC1155Metadata.sol";

import { ERC2771ContextUpgradeable } from "../../dynamic-contracts/extension/ERC2771ContextUpgradeable.sol";
import { PrimarySale } from "../../dynamic-contracts/extension/PrimarySale.sol";
import { PlatformFee } from "../../dynamic-contracts/extension/PlatformFee.sol";
import { Royalty, IERC165 } from "../../dynamic-contracts/extension/Royalty.sol";
import { LazyMint } from "../../dynamic-contracts/extension/LazyMint.sol";
import { Drop1155 } from "../../dynamic-contracts/extension/Drop1155.sol";
import { ContractMetadata } from "../../dynamic-contracts/extension/ContractMetadata.sol";
import { Ownable } from "../../dynamic-contracts/extension/Ownable.sol";
import { DefaultOperatorFiltererUpgradeable } from "../../dynamic-contracts/extension/DefaultOperatorFiltererUpgradeable.sol";
import { PermissionsStorage } from "../../dynamic-contracts/extension/Permissions.sol";

contract DropERC1155Logic is
    ContractMetadata,
    PlatformFee,
    Royalty,
    PrimarySale,
    Ownable,
    LazyMint,
    Drop1155,
    ERC2771ContextUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    ERC1155Upgradeable
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

    /// @dev Max bps in the thirdweb system.
    uint256 private constant MAX_BPS = 10_000;

    /*///////////////////////////////////////////////////////////////
                               Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when the global max supply of a token is updated.
    event MaxTotalSupplyUpdated(uint256 tokenId, uint256 maxTotalSupply);

    /// @dev Emitted when the sale recipient for a particular tokenId is updated.
    event SaleRecipientForTokenUpdated(uint256 indexed tokenId, address saleRecipient);

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 1155 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the uri for a given tokenId.
    function uri(uint256 _tokenId) public view override returns (string memory) {
        string memory batchUri = _getBaseURI(_tokenId);
        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC1155Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155Metadata).interfaceId;
    }

    /*///////////////////////////////////////////////////////////////
                        Setter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a module admin set a max total supply for token.
    function setMaxTotalSupply(uint256 _tokenId, uint256 _maxTotalSupply) external {
        require(_hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not admin.");

        DropERC1155Storage.Data storage data = DropERC1155Storage.dropERC1155Storage();
        data.maxTotalSupply[_tokenId] = _maxTotalSupply;
        emit MaxTotalSupplyUpdated(_tokenId, _maxTotalSupply);
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function setSaleRecipientForToken(uint256 _tokenId, address _saleRecipient) external {
        require(_hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not admin.");

        DropERC1155Storage.Data storage data = DropERC1155Storage.dropERC1155Storage();
        data.saleRecipient[_tokenId] = _saleRecipient;
        emit SaleRecipientForTokenUpdated(_tokenId, _saleRecipient);
    }

    /*///////////////////////////////////////////////////////////////
                        Getter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Token name
    function name() public view returns (string memory) {
        DropERC1155Storage.Data storage data = DropERC1155Storage.dropERC1155Storage();
        return data.name;
    }

    /// @dev Token symbol
    function symbol() public view returns (string memory) {
        DropERC1155Storage.Data storage data = DropERC1155Storage.dropERC1155Storage();
        return data.symbol;
    }

    /// @dev Total circulating supply of tokens with a given tokenId.
    function totalSupply(uint256 _tokenId) public view returns (uint256) {
        DropERC1155Storage.Data storage data = DropERC1155Storage.dropERC1155Storage();
        return data.totalSupply[_tokenId];
    }

    /// @dev Global max total supply of tokens with a given tokenId.
    function maxTotalSupply(uint256 _tokenId) public view returns (uint256) {
        DropERC1155Storage.Data storage data = DropERC1155Storage.dropERC1155Storage();
        return data.maxTotalSupply[_tokenId];
    }

    /// @dev Address of the recipient of primary sales for a given tokenId.
    function saleRecipient(uint256 _tokenId) public view returns (address) {
        DropERC1155Storage.Data storage data = DropERC1155Storage.dropERC1155Storage();
        return data.saleRecipient[_tokenId];
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Runs before every `claim` function call.
    function _beforeClaim(
        uint256 _tokenId,
        address,
        uint256 _quantity,
        address,
        uint256,
        AllowlistProof calldata,
        bytes memory
    ) internal view override {
        DropERC1155Storage.Data storage data = DropERC1155Storage.dropERC1155Storage();

        uint256 _maxTotalSupply = data.maxTotalSupply[_tokenId];
        require(
            _maxTotalSupply == 0 || data.totalSupply[_tokenId] + _quantity <= _maxTotalSupply,
            "exceed max total supply"
        );
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectPriceOnClaim(
        uint256 _tokenId,
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal override {
        if (_pricePerToken == 0) {
            return;
        }

        (address platformFeeRecipient, uint16 platformFeeBps) = getPlatformFeeInfo();

        DropERC1155Storage.Data storage data = DropERC1155Storage.dropERC1155Storage();
        address _saleRecipientFromStorage = data.saleRecipient[_tokenId];
        address _saleRecipient = _primarySaleRecipient == address(0)
            ? (_saleRecipientFromStorage == address(0) ? primarySaleRecipient() : _saleRecipientFromStorage)
            : _primarySaleRecipient;

        uint256 totalPrice = _quantityToClaim * _pricePerToken;
        uint256 platformFees = (totalPrice * platformFeeBps) / MAX_BPS;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            if (msg.value != totalPrice) {
                revert("!Price");
            }
        } else {
            require(msg.value == 0, "!ZeroValue");
        }

        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), platformFeeRecipient, platformFees);
        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), _saleRecipient, totalPrice - platformFees);
    }

    /// @dev Transfers the NFTs being claimed.
    function transferTokensOnClaim(
        address _to,
        uint256 _tokenId,
        uint256 _quantityBeingClaimed
    ) internal override {
        _mint(_to, _tokenId, _quantityBeingClaimed, "");
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetPlatformFeeInfo() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
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

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function _canLazyMint() internal view virtual override returns (bool) {
        return _hasRole(MINTER_ROLE, _msgSender());
    }

    /// @dev Returns whether operator restriction can be set in the given execution context.
    function _canSetOperatorRestriction() internal virtual override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /// @dev The tokenId of the next NFT that will be minted / lazy minted.
    function nextTokenIdToMint() external view returns (uint256) {
        return nextTokenIdToLazyMint();
    }

    /// @dev Lets a token owner burn multiple tokens they own at once (i.e. destroy for good)
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved."
        );

        _burnBatch(account, ids, values);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!_hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            require(
                _hasRole(TRANSFER_ROLE, from) || _hasRole(TRANSFER_ROLE, to),
                "restricted to TRANSFER_ROLE holders."
            );
        }

        DropERC1155Storage.Data storage data = DropERC1155Storage.dropERC1155Storage();
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                data.totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                data.totalSupply[ids[i]] -= amounts[i];
            }
        }
    }

    /// @dev See {ERC1155-setApprovalForAll}
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override(ERC1155Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override(ERC1155Upgradeable) onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _hasRole(bytes32 role, address addr) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        return data._hasRole[role][addr];
    }

    function _dropMsgSender() internal view virtual override returns (address) {
        return _msgSender();
    }

    function _msgSender() internal view virtual override(Context, ERC2771ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }
}
