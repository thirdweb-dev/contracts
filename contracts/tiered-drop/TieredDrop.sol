// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

import "lib/dynamic-contracts/src/presets/BaseRouter.sol";

import "../extension/Multicall.sol";

import "../dynamic-contracts/extension/Initializable.sol";
import "../dynamic-contracts/extension/Permissions.sol";
import "../dynamic-contracts/extension/ERC2771ContextUpgradeable.sol";

import "../dynamic-contracts/init/ContractMetadataInit.sol";
import "../dynamic-contracts/init/ERC721AInit.sol";
import "../dynamic-contracts/init/OwnableInit.sol";
import "../dynamic-contracts/init/PermissionsEnumerableInit.sol";
import "../dynamic-contracts/init/PrimarySaleInit.sol";
import "../dynamic-contracts/init/RoyaltyInit.sol";
import "../dynamic-contracts/init/SignatureActionInit.sol";
import "../dynamic-contracts/init/DefaultOperatorFiltererInit.sol";

/**
 *  Defualt extensions to add:
 *      - TieredDropLogic
 *      - PermissionsEnumerable
 */

contract TieredDrop is
    Initializable,
    Multicall,
    ERC2771ContextUpgradeable,
    BaseRouter,
    DefaultOperatorFiltererInit,
    PrimarySaleInit,
    ContractMetadataInit,
    ERC721AInit,
    OwnableInit,
    PermissionsEnumerableInit,
    RoyaltyInit,
    SignatureActionInit
{
    /*///////////////////////////////////////////////////////////////
                    Constructor and Initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(Extension[] memory _extensions) BaseRouter(_extensions) {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint16 _royaltyBps
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init(_trustedForwarders);
        __ERC721A_init(_name, _symbol);
        __SignatureAction_init();

        _setupContractURI(_contractURI);
        _setupOwner(_defaultAdmin);

        _setupRoles(_defaultAdmin);

        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupPrimarySaleRecipient(_saleRecipient);

        _setupOperatorFilterer();
    }

    function _setupRoles(address _defaultAdmin) internal onlyInitializing {
        bytes32 _operatorRole = keccak256("OPERATOR_ROLE");
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        bytes32 _minterRole = keccak256("MINTER_ROLE");
        bytes32 _defaultAdminRole = 0x00;

        _setupRole(_defaultAdminRole, _defaultAdmin);
        _setupRole(_minterRole, _defaultAdmin);
        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));
        _setupRole(_operatorRole, _defaultAdmin);
        _setupRole(_operatorRole, address(0));
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a plugin can be set in the given execution context.
    function _canSetExtension() internal view virtual override returns (bool) {
        bytes32 defaultAdminRole = 0x00;
        return _hasRole(defaultAdminRole, _msgSender());
    }

    /// @dev Checks whether an account holds the given role.
    function _hasRole(bytes32 role, address addr) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        return data._hasRole[role][addr];
    }
}
