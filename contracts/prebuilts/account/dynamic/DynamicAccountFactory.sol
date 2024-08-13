// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

// Utils
import "../utils/BaseAccountFactory.sol";
import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

// Extensions
import "../../../extension/upgradeable//PermissionsEnumerable.sol";
import "../../../extension/upgradeable//ContractMetadata.sol";

// Smart wallet implementation
import { DynamicAccount, IEntryPoint } from "./DynamicAccount.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

contract DynamicAccountFactory is BaseAccountFactory, ContractMetadata, PermissionsEnumerable {
    address public constant ENTRYPOINT_ADDRESS = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _defaultAdmin,
        IExtension.Extension[] memory _defaultExtensions
    )
        BaseAccountFactory(
            payable(address(new DynamicAccount(IEntryPoint(ENTRYPOINT_ADDRESS), _defaultExtensions))),
            ENTRYPOINT_ADDRESS
        )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Called in `createAccount`. Initializes the account contract created in `createAccount`.
    function _initializeAccount(address _account, address _admin, bytes calldata _data) internal override {
        DynamicAccount(payable(_account)).initialize(_admin, _data);
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Returns the sender in the given execution context.
    function _msgSender() internal view override(Multicall, Permissions) returns (address) {
        return msg.sender;
    }
}
