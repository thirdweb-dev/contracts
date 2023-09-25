// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./CoreRouter.sol";
import "./eip/queryable/ERC721AQueryableUpgradeable.sol";

contract ERC721Router is CoreRouter, ERC721AQueryableUpgradeable {
    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/
    constructor(Extension[] memory _defaultExtensions) CoreRouter(_defaultExtensions) {}

    /*///////////////////////////////////////////////////////////////
                                Initialize
    //////////////////////////////////////////////////////////////*/

    /// @notice Initliazes the contract.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarder,
        Extension[] memory _initExtensions
    ) external initializer initializerERC721A {
        // Initialize with extensions
        __BaseRouter_init_checked(_initExtensions);

        // Initialize ERC2771Context
        __ERC2771Context_init(_trustedForwarder);

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
}
