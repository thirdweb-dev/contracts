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

import { DropERC20Storage } from "./DropERC20Storage.sol";

import "../../lib/TWStrings.sol";
import "../../lib/CurrencyTransferLib.sol";

import { Context, ERC20BurnableUpgradeable } from "../../dynamic-contracts/eip/ERC20BurnableUpgradeable.sol";
import { ERC20VotesUpgradeable, ERC20VotesStorage, ERC20Upgradeable } from "../../dynamic-contracts/eip/ERC20VotesUpgradeable.sol";

import { IERC2771Context } from "../../extension/interface/IERC2771Context.sol";

import { ERC2771ContextUpgradeable } from "../../dynamic-contracts/extension/ERC2771ContextUpgradeable.sol";
import { PrimarySale } from "../../dynamic-contracts/extension/PrimarySale.sol";
import { PlatformFee } from "../../dynamic-contracts/extension/PlatformFee.sol";
import { Drop } from "../../dynamic-contracts/extension/Drop.sol";
import { ContractMetadata } from "../../dynamic-contracts/extension/ContractMetadata.sol";
import { PermissionsStorage } from "../../dynamic-contracts/extension/Permissions.sol";

contract DropERC20Logic is
    ContractMetadata,
    PlatformFee,
    PrimarySale,
    Drop,
    ERC2771ContextUpgradeable,
    ERC20BurnableUpgradeable,
    ERC20VotesUpgradeable
{
    using TWStrings for uint256;

    /*///////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/

    /// @dev Default admin role for all roles. Only accounts with this role can grant/revoke other roles.
    bytes32 private constant DEFAULT_ADMIN_ROLE = 0x00;
    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    /// @dev Max bps in the thirdweb system.
    uint256 private constant MAX_BPS = 10_000;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when the global max supply of tokens is updated.
    event MaxTotalSupplyUpdated(uint256 maxTotalSupply);

    /*///////////////////////////////////////////////////////////////
                        Setter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a contract admin set the global maximum supply tokens.
    function setMaxTotalSupply(uint256 _maxTotalSupply) external {
        require(_hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not admin.");

        DropERC20Storage.Data storage data = DropERC20Storage.dropERC20Storage();
        data.maxTotalSupply = _maxTotalSupply;
        emit MaxTotalSupplyUpdated(_maxTotalSupply);
    }

    /*///////////////////////////////////////////////////////////////
                        Getter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Global max total supply of tokens.
    function maxTotalSupply() public view returns (uint256) {
        DropERC20Storage.Data storage data = DropERC20Storage.dropERC20Storage();
        return data.maxTotalSupply;
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Runs before every `claim` function call.
    function _beforeClaim(
        address,
        uint256 _quantity,
        address,
        uint256,
        AllowlistProof calldata,
        bytes memory
    ) internal view override {
        DropERC20Storage.Data storage data = DropERC20Storage.dropERC20Storage();
        uint256 _maxTotalSupply = data.maxTotalSupply;
        require(_maxTotalSupply == 0 || totalSupply() + _quantity <= _maxTotalSupply, "exceed max total supply.");
    }

    /// @dev Collects and distributes the primary sale value of tokens being claimed.
    function _collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal override {
        if (_pricePerToken == 0) {
            return;
        }

        // `_pricePerToken` is interpreted as price per 1 ether unit of the ERC20 tokens.
        uint256 totalPrice = (_quantityToClaim * _pricePerToken) / 1 ether;
        require(totalPrice > 0, "quantity too low");

        bool validMsgValue;
        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            validMsgValue = msg.value == totalPrice;
        } else {
            validMsgValue = msg.value == 0;
        }
        require(validMsgValue, "!V");

        address saleRecipient = _primarySaleRecipient == address(0) ? primarySaleRecipient() : _primarySaleRecipient;

        uint256 fees;
        address feeRecipient;

        PlatformFeeType feeType = getPlatformFeeType();
        if (feeType == PlatformFeeType.Flat) {
            (feeRecipient, fees) = getFlatPlatformFeeInfo();
        } else {
            uint16 platformFeeBps;
            (feeRecipient, platformFeeBps) = getPlatformFeeInfo();
            fees = (totalPrice * platformFeeBps) / MAX_BPS;
        }

        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), feeRecipient, fees);
        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), saleRecipient, totalPrice - fees);
    }

    /// @dev Transfers the tokens being claimed.
    function _transferTokensOnClaim(address _to, uint256 _quantityBeingClaimed) internal override returns (uint256) {
        _mint(_to, _quantityBeingClaimed);
        return 0;
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetPlatformFeeInfo() internal view override returns (bool) {
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

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetClaimConditions() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function _mint(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._mint(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._burn(account, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    /// @dev Runs on every transfer.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable) {
        super._beforeTokenTransfer(from, to, amount);

        if (!_hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            require(_hasRole(TRANSFER_ROLE, from) || _hasRole(TRANSFER_ROLE, to), "transfers restricted.");
        }
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
