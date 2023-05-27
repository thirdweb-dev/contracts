// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

// Utils
import "lib/dynamic-contracts/src/presets/BaseRouter.sol";
import "../utils/BaseAccountFactory.sol";

// Extensions
import "../../dynamic-contracts/extension/PermissionsEnumerable.sol";
import "../../dynamic-contracts/extension/ContractMetadata.sol";

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
        BaseAccountFactory(payable(address(new ManagedAccount(_entrypoint, address(this)))))
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    receive() external payable override {
        revert("Cannot accept ether.");
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

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
