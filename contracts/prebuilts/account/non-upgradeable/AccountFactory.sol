// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

// Utils
import "../utils/BaseAccountFactory.sol";
import "../utils/BaseAccount.sol";
import "../../../external-deps/openzeppelin/proxy/Clones.sol";

// Extensions
import "../../../extension/upgradeable//PermissionsEnumerable.sol";
import "../../../extension/upgradeable//ContractMetadata.sol";

// Interface
import "../interface/IEntrypoint.sol";

// Smart wallet implementation
import { Account } from "./Account.sol";

import "forge-std/console.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

contract AccountFactory is BaseAccountFactory, ContractMetadata, PermissionsEnumerable {
    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        IEntryPoint _entrypoint
    ) BaseAccountFactory(address(new Account(_entrypoint, address(this))), address(_entrypoint)) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Called in `createAccount`. Initializes the account contract created in `createAccount`.
    function _initializeAccount(
        address _account,
        address _admin,
        address commonGuardian,
        bytes calldata _data
    ) internal override {
        console.log("AccountLock address in AccountFactory used to initialize account clone", address(accountLock));

        Account(payable(_account)).initialize(_admin, commonGuardian, address(accountLock), _data);
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
