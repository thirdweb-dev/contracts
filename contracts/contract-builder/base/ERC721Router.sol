// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../CoreRouter.sol";

import "../../extension/upgradeable/init/PermissionsEnumerableInit.sol";
import "../../extension/upgradeable/init/ERC721AQueryableInit.sol";

import "../../extension/interface/IPermissions.sol";

contract ERC721Router is CoreRouter, ERC721AQueryableInit, PermissionsEnumerableInit {
    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    // Default extensions expected: [ERC721A, PermissionsEnumerable].
    constructor(Extension[] memory _defaultExtensions) CoreRouter(_defaultExtensions) {}

    /*///////////////////////////////////////////////////////////////
                                Initialize
    //////////////////////////////////////////////////////////////*/

    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI
    ) external initializer initializerERC721A {
        // Initialize ERC721A
        __ERC721A_init(_name, _symbol);

        // Initialize contract metadata
        _setupContractURI(_contractURI);

        // Initialize ownership
        _setupOwner(_defaultAdmin);

        // Default admin role.
        _setupRole(0x00, _defaultAdmin);

        // Extension role
        bytes32 extRole = keccak256("EXTENSION_ROLE");
        _setupRole(extRole, _defaultAdmin);
        _setRoleAdmin(extRole, extRole);
    }

    /*///////////////////////////////////////////////////////////////
                        Override: Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a extension can be added/replaced/removed in the given execution context.
    function isAuthorizedCallToUpgrade() internal view virtual override returns (bool) {
        // Check: extension role
        try IPermissions(address(this)).hasRole(keccak256("EXTENSION_ROLE"), _msgSender()) returns (bool success) {
            return success;
        } catch {}

        return false;
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        // Check: default admin role
        try IPermissions(address(this)).hasRole(0x00, _msgSender()) returns (bool success) {
            return success;
        } catch {}

        return false;
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        // Check: default admin role
        try IPermissions(address(this)).hasRole(0x00, _msgSender()) returns (bool success) {
            return success;
        } catch {}

        return false;
    }
}
