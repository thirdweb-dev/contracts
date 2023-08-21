// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

import "@thirdweb-dev/dynamic-contracts/src/presets/BaseRouterWithDefaults.sol";

import "../../extension/Multicall.sol";

import "../../dynamic-contracts/extension/Initializable.sol";
import "../../dynamic-contracts/extension/Permissions.sol";
import "../../dynamic-contracts/extension/ERC2771ContextUpgradeable.sol";

import "../../dynamic-contracts/init/ContractMetadataInit.sol";
import "../../dynamic-contracts/init/PlatformFeeInit.sol";
import "../../dynamic-contracts/init/RoyaltyInit.sol";
import "../../dynamic-contracts/init/PrimarySaleInit.sol";
import "../../dynamic-contracts/init/OwnableInit.sol";
import "../../dynamic-contracts/init/ERC721AInit.sol";
import "../../dynamic-contracts/init/PermissionsEnumerableInit.sol";
import "../../dynamic-contracts/init/DefaultOperatorFiltererInit.sol";
import "../../dynamic-contracts/init/ReentrancyGuardInit.sol";

contract BurnToClaimDropERC721 is
    Initializable,
    Multicall,
    ERC2771ContextUpgradeable,
    BaseRouterWithDefaults,
    DefaultOperatorFiltererInit,
    ContractMetadataInit,
    PlatformFeeInit,
    RoyaltyInit,
    PrimarySaleInit,
    OwnableInit,
    PermissionsEnumerableInit,
    ERC721AInit
{
    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(Extension[] memory _extensions) BaseRouterWithDefaults(_extensions) {
        _disableInitializers();
    }

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init(_trustedForwarders);
        __ERC721A_init(_name, _symbol);

        _setupContractURI(_contractURI);
        _setupOwner(_defaultAdmin);

        _setupRoles(_defaultAdmin);

        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupPrimarySaleRecipient(_saleRecipient);

        _setupOperatorFilterer();
    }

    function _setupRoles(address _defaultAdmin) internal onlyInitializing {
        bytes32 _operatorRole = keccak256("OPERATOR_ROLE");
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        bytes32 _minterRole = keccak256("MINTER_ROLE");
        bytes32 _extensionRole = keccak256("EXTENSION_ROLE");
        bytes32 _defaultAdminRole = 0x00;

        _setupRole(_defaultAdminRole, _defaultAdmin);
        _setupRole(_minterRole, _defaultAdmin);
        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));
        _setupRole(_operatorRole, _defaultAdmin);
        _setupRole(_operatorRole, address(0));
        _setupRole(_extensionRole, _defaultAdmin);
        _setRoleAdmin(_extensionRole, _extensionRole);
    }

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    // /// @dev See ERC 165
    // function supportsInterface(bytes4 interfaceId)
    //     public
    //     view
    //     virtual
    //     override(ERC721AUpgradeable, IERC165)
    //     returns (bool)
    // {
    //     return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
    // }

    /*///////////////////////////////////////////////////////////////
                        Contract identifiers
    //////////////////////////////////////////////////////////////*/

    function contractType() external pure returns (bytes32) {
        return bytes32("BurnToClaimDropERC721");
    }

    function contractVersion() external pure returns (uint8) {
        return uint8(5);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether an extension can be set in the given execution context.
    function _canSetExtension(Extension memory) internal view virtual override returns (bool) {
        return _hasRole(keccak256("EXTENSION_ROLE"), msg.sender);
    }

    /// @dev Checks whether an account holds the given role.
    function _hasRole(bytes32 role, address addr) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        return data._hasRole[role][addr];
    }
}
