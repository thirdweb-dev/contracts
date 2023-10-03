// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

// Utils
import "@thirdweb-dev/dynamic-contracts/src/presets/BaseRouter.sol";
import "../utils/BaseAccountFactory.sol";

// Extensions
import "../../../extension/upgradeable//PermissionsEnumerable.sol";
import "../../../extension/upgradeable//ContractMetadata.sol";

// Smart wallet implementation
import { ManagedAccount, IEntryPoint } from "./ManagedAccount.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

contract ManagedAccountFactory is BaseAccountFactory, ContractMetadata, PermissionsEnumerable, BaseRouter {
    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(IEntryPoint _entrypoint, Extension[] memory _defaultExtensions)
        BaseRouter(_defaultExtensions)
        BaseAccountFactory(payable(address(new ManagedAccount(_entrypoint, address(this)))), address(_entrypoint))
    {
        __BaseRouter_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        bytes32 _extensionRole = keccak256("EXTENSION_ROLE");
        _setupRole(_extensionRole, msg.sender);
        _setRoleAdmin(_extensionRole, _extensionRole);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Called in `createAccount`. Initializes the account contract created in `createAccount`.
    function _initializeAccount(
        address _account,
        address _admin,
        bytes calldata _data
    ) internal override {
        ManagedAccount(payable(_account)).initialize(_admin, _data);
    }

    /// @dev Returns whether all relevant permission and other checks are met before any upgrade.
    function _isAuthorizedCallToUpgrade() internal view virtual override returns (bool) {
        return hasRole(keccak256("EXTENSION_ROLE"), msg.sender);
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
