// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

// Base
import "lib/dynamic-contracts/src/presets/BaseRouter.sol";

// Fixed extensions
import "../extension/Multicall.sol";
import "../dynamic-contracts/extension/Initializable.sol";

// Utils
import "../dynamic-contracts/init/ContractMetadataInit.sol";
import "../dynamic-contracts/init/PermissionsInit.sol";

contract TWAccountRouter is Initializable, Multicall, BaseRouter, ContractMetadataInit, PermissionsInit {
    /*///////////////////////////////////////////////////////////////
                                Constants
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant EXTENSION_ADMIN_ROLE = keccak256("EXTENSION_ADMIN_ROLE");

    /*///////////////////////////////////////////////////////////////
                        Constructor and Initializer
    //////////////////////////////////////////////////////////////*/

    constructor(Extension[] memory _defaultExtensions) BaseRouter(_defaultExtensions) {}

    function initialize(address _defaultAdmin, string memory _contractURI) public virtual initializer {
        _setupRole(EXTENSION_ADMIN_ROLE, _defaultAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);

        _setupContractURI(_contractURI);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a extension can be set in the given execution context.
    function _canSetExtension() internal view virtual returns (bool) {
        return _hasRole(EXTENSION_ADMIN_ROLE, msg.sender);
    }

    /// @dev Checks whether an account holds the given role.
    function _hasRole(bytes32 role, address addr) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        return data._hasRole[role][addr];
    }
}
