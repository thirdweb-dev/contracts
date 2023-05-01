// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

// Utils

import "../utils/BaseRouter.sol";
import "../../dynamic-contracts/extension/PermissionsEnumerable.sol";
import "../utils/BaseAccountFactory.sol";
import "../utils/BaseAccount.sol";
import "../../openzeppelin-presets/proxy/Clones.sol";

// Smart wallet implementation
import "../utils/AccountExtension.sol";
import { ManagedAccount, IEntryPoint } from "./ManagedAccount.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

contract ManagedAccountFactory is BaseAccountFactory, PermissionsEnumerable, BaseRouter {
    /*///////////////////////////////////////////////////////////////
                                State
    //////////////////////////////////////////////////////////////*/

    address public immutable defaultExtension;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(IEntryPoint _entrypoint) BaseAccountFactory(payable(address(new ManagedAccount(_entrypoint)))) {
        defaultExtension = address(new AccountExtension(address(_entrypoint), address(this)));
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the extension implementation address stored in router, for the given function.
    function getImplementationForFunction(bytes4 _functionSelector) public view override returns (address) {
        address impl = getExtensionForFunction(_functionSelector).implementation;
        return impl != address(0) ? impl : defaultExtension;
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

    /// @dev Returns whether an extension can be set in the given execution context.
    function _canSetExtension() internal view virtual override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
