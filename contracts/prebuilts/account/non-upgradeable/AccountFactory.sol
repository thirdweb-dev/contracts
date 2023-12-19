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
import { Guardian } from "../utils/Guardian.sol";

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
    // Events //
    event AccountFactoryContractDeployed(address indexed);

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        IEntryPoint _entrypoint
    ) BaseAccountFactory(address(new Account(_entrypoint, address(this))), address(_entrypoint)) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        emit AccountFactoryContractDeployed(address(this));
    }

    ///@dev  returns cross chain contract details
    // function getCrossChainData() external view returns (address, address) {
    //     return (address(crossChainTokenTransfer), address(crossChainTokenTransferMaster));
    // }

    ///@dev  returns Account lock contract details
    function getAccountLock() external view returns (address) {
        return (address(accountLock));
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Called in `createAccount`. Initializes the account contract created in `createAccount`.
    function _initializeAccount(address _account, address _admin, bytes calldata _data) internal override {
        console.log("AccountLock address in AccountFactory used to initialize account clone", address(accountLock));

        Account(payable(_account)).initialize(_admin, _data, address(accountLock));
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
