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

// CCIP
import { CrossChainTokenTransfer } from "../utils/CrossChainTokenTransfer.sol";
import { CrossChainTokenTransferMaster } from "../utils/CrossChainTokenTransferMaster.sol";
import { AccountRecovery } from "../utils/AccountRecovery.sol";

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
    event CrossChainTokenTransferContractDeployed(address indexed);
    event CrossChainTokenTransferMasterContractDeployed(address indexed);

    // States //
    CrossChainTokenTransfer public crossChainTokenTransfer;
    CrossChainTokenTransferMaster public crossChainTokenTransferMaster;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        IEntryPoint _entrypoint,
        address _router,
        address _link
    ) BaseAccountFactory(address(new Account(_entrypoint, address(this))), address(_entrypoint)) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        crossChainTokenTransfer = new CrossChainTokenTransfer(_router, _link);
        crossChainTokenTransferMaster = new CrossChainTokenTransferMaster(address(crossChainTokenTransfer), _link);

        emit AccountFactoryContractDeployed(address(this));
        emit CrossChainTokenTransferContractDeployed(address(crossChainTokenTransfer));
        emit CrossChainTokenTransferMasterContractDeployed(address(crossChainTokenTransferMaster));
    }

    ///@dev  returns cross chain contract details
    function getCrossChainData() external view returns (address, address) {
        return (address(crossChainTokenTransfer), address(crossChainTokenTransferMaster));
    }

    ///@dev  returns Account lock contract details
    function getAccountLock() external view returns (address) {
        return (address(accountLock));
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
        Account(payable(_account)).initialize(_admin, commonGuardian, address(accountLock), _data);
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
