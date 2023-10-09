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

import "../../extension/Multicall.sol";
import "../../extension/upgradeable/Initializable.sol";
import "../../extension/upgradeable/init/ContractMetadataInit.sol";
import "../../extension/upgradeable/init/RoyaltyInit.sol";
import "../../extension/upgradeable/init/PrimarySaleInit.sol";
import "../../extension/upgradeable/init/OwnableInit.sol";
import "../../extension/upgradeable/init/PermissionsEnumerableInit.sol";
import "../../extension/upgradeable/init/ERC2771ContextInit.sol";
import "../../extension/upgradeable/init/ERC721AQueryableInit.sol";

contract EvolvingNFT is
    Initializable,
    BaseRouter,
    Multicall,
    ERC721AQueryableInit,
    ERC2771ContextInit,
    ContractMetadataInit,
    RoyaltyInit,
    PrimarySaleInit,
    OwnableInit,
    PermissionsEnumerableInit
{
    /// @dev Only EXTENSION_ROLE holders can update the contract's extensions.
    bytes32 private constant EXTENSION_ROLE = keccak256("EXTENSION_ROLE");

    constructor(Extension[] memory _extensions) BaseRouter(_extensions) {
        _disableInitializers();
    }

    /// @dev Initializes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) external initializer initializerERC721A {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");

        // Initialize extensions
        __BaseRouter_init();

        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init(_trustedForwarders);
        __ERC721A_init(_name, _symbol);

        _setupContractURI(_contractURI);
        _setupOwner(_defaultAdmin);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(EXTENSION_ROLE, _defaultAdmin);
        _setupRole(keccak256("MINTER_ROLE"), _defaultAdmin);
        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));

        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupPrimarySaleRecipient(_saleRecipient);

        _setupRole(EXTENSION_ROLE, _defaultAdmin);
        _setRoleAdmin(EXTENSION_ROLE, EXTENSION_ROLE);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev The start token ID for the contract.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @dev Returns whether all relevant permission and other checks are met before any upgrade.
    function _isAuthorizedCallToUpgrade() internal view virtual override returns (bool) {
        return _hasRole(EXTENSION_ROLE, msg.sender);
    }

    /// @dev Checks whether an account has a particular role.
    function _hasRole(bytes32 _role, address _account) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.data();
        return data._hasRole[_role][_account];
    }
}
