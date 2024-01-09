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

import "@thirdweb-dev/dynamic-contracts/src/presets/BaseRouter.sol";

import "../../../extension/Multicall.sol";

import "../../../extension/upgradeable/Initializable.sol";
import "../../../extension/upgradeable/Permissions.sol";
import "../../../extension/upgradeable/ERC2771ContextUpgradeable.sol";

import "../../../extension/upgradeable/init/ContractMetadataInit.sol";
import "../../../extension/upgradeable/init/PlatformFeeInit.sol";
import "../../../extension/upgradeable/init/RoyaltyInit.sol";
import "../../../extension/upgradeable/init/PrimarySaleInit.sol";
import "../../../extension/upgradeable/init/OwnableInit.sol";
import "../../../extension/upgradeable/init/ERC721AInit.sol";
import "../../../extension/upgradeable/init/PermissionsEnumerableInit.sol";
import "../../../extension/upgradeable/init/ReentrancyGuardInit.sol";

contract BurnToClaimDropERC721 is
    Initializable,
    Multicall,
    ERC2771ContextUpgradeable,
    BaseRouter,
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

    constructor(Extension[] memory _extensions) BaseRouter(_extensions) {
        _disableInitializers();
    }

    /// @notice Initializes the contract.
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
        // Initialize extensions
        __BaseRouter_init();

        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init(_trustedForwarders);
        __ERC721A_init(_name, _symbol);

        _setupContractURI(_contractURI);
        _setupOwner(_defaultAdmin);

        _setupRoles(_defaultAdmin);

        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupPrimarySaleRecipient(_saleRecipient);
    }

    /// @dev Called in the initialize function. Sets up roles.
    function _setupRoles(address _defaultAdmin) internal onlyInitializing {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        bytes32 _minterRole = keccak256("MINTER_ROLE");
        bytes32 _extensionRole = keccak256("EXTENSION_ROLE");
        bytes32 _defaultAdminRole = 0x00;

        _setupRole(_defaultAdminRole, _defaultAdmin);
        _setupRole(_minterRole, _defaultAdmin);
        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));
        _setupRole(_extensionRole, _defaultAdmin);
        _setRoleAdmin(_extensionRole, _extensionRole);
    }

    /*///////////////////////////////////////////////////////////////
                        Contract identifiers
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the type of contract.
    function contractType() external pure returns (bytes32) {
        return bytes32("BurnToClaimDropERC721");
    }

    /// @notice Returns the contract version.
    function contractVersion() external pure returns (uint8) {
        return uint8(5);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether all relevant permission and other checks are met before any upgrade.
    function _isAuthorizedCallToUpgrade() internal view virtual override returns (bool) {
        return _hasRole(keccak256("EXTENSION_ROLE"), msg.sender);
    }

    /// @dev Checks whether an account holds the given role.
    function _hasRole(bytes32 role, address addr) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.data();
        return data._hasRole[role][addr];
    }

    /// @notice Returns the sender in the given execution context.
    function _msgSender()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, Multicall)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }
}
