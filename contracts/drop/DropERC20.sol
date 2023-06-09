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

import "lib/dynamic-contracts/src/presets/BaseRouter.sol";

import "../extension/Multicall.sol";

import "../dynamic-contracts/extension/Initializable.sol";
import "../dynamic-contracts/extension/Permissions.sol";
import "../dynamic-contracts/extension/ERC2771ContextUpgradeable.sol";

import "../dynamic-contracts/init/ContractMetadataInit.sol";
import "../dynamic-contracts/init/PlatformFeeInit.sol";
import "../dynamic-contracts/init/PrimarySaleInit.sol";
import "../dynamic-contracts/init/PermissionsEnumerableInit.sol";
import "../dynamic-contracts/init/ReentrancyGuardInit.sol";
import "../dynamic-contracts/init/ERC20Init.sol";
import "../dynamic-contracts/init/ERC20PermitInit.sol";

contract DropERC20 is
    Initializable,
    Multicall,
    ERC2771ContextUpgradeable,
    BaseRouter,
    ContractMetadataInit,
    PlatformFeeInit,
    PrimarySaleInit,
    PermissionsEnumerableInit,
    ERC20Init,
    ERC20PermitInit
{
    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
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
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init(_trustedForwarders);
        __ERC20Permit_init(_name);
        __ERC20_init_unchained(_name, _symbol);

        _setupContractURI(_contractURI);

        _setupRoles(_defaultAdmin);

        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
        _setupPrimarySaleRecipient(_saleRecipient);
    }

    function _setupRoles(address _defaultAdmin) internal onlyInitializing {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        bytes32 _extensionRole = keccak256("EXTENSION_ROLE");
        bytes32 _defaultAdminRole = 0x00;

        _setupRole(_defaultAdminRole, _defaultAdmin);
        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));

        _setupRole(_extensionRole, _defaultAdmin);
        _setRoleAdmin(_extensionRole, _extensionRole);
    }

    /*///////////////////////////////////////////////////////////////
                        Contract identifiers
    //////////////////////////////////////////////////////////////*/

    function contractType() external pure returns (bytes32) {
        return bytes32("DropERC20");
    }

    function contractVersion() external pure returns (uint8) {
        return uint8(5);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a plugin can be set in the given execution context.
    function _canSetExtension() internal view virtual override returns (bool) {
        _hasRole(keccak256("EXTENSION_ROLE"), msg.sender);
    }

    /// @dev Checks whether an account holds the given role.
    function _hasRole(bytes32 role, address addr) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        return data._hasRole[role][addr];
    }
}
