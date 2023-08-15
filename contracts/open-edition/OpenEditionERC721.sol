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

import "../dynamic-contracts/extension/Initializable.sol";
import "../extension/Multicall.sol";
import "../dynamic-contracts/init/ContractMetadataInit.sol";
import "../dynamic-contracts/init/RoyaltyInit.sol";
import "../dynamic-contracts/init/PrimarySaleInit.sol";
import "../dynamic-contracts/init/OwnableInit.sol";
import "../dynamic-contracts/init/PermissionsInit.sol";
import "../dynamic-contracts/init/PlatformFeeInit.sol";
import "../dynamic-contracts/init/ERC2771ContextInit.sol";
import "../dynamic-contracts/init/ERC721AQueryableInit.sol";
import "../dynamic-contracts/init/DefaultOperatorFiltererInit.sol";

contract OpenEditionERC721 is
    Initializable,
    BaseRouter,
    Multicall,
    ERC721AQueryableInit,
    ERC2771ContextInit,
    ContractMetadataInit,
    RoyaltyInit,
    PrimarySaleInit,
    PlatformFeeInit,
    OwnableInit,
    PermissionsInit,
    DefaultOperatorFiltererInit
{
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s.
    bytes32 private constant EXTENSION_ROLE = keccak256("EXTENSION_ROLE");

    constructor(Extension[] memory _extensions) BaseRouter(_extensions) {
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
    ) external initializer initializerERC721A {
        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init(_trustedForwarders);
        __ERC721A_init(_name, _symbol);

        _setupContractURI(_contractURI);
        _setupOwner(_defaultAdmin);
        _setupOperatorFilterer();

        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupPrimarySaleRecipient(_saleRecipient);
        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);

        _setupRoles(_defaultAdmin);
    }

    function _setupRoles(address _defaultAdmin) internal {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(keccak256("MINTER_ROLE"), _defaultAdmin);
        _setupRole(keccak256("TRANSFER_ROLE"), _defaultAdmin);
        _setupRole(keccak256("TRANSFER_ROLE"), address(0));
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev The start token ID for the contract.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @dev Returns whether a extension can be set in the given execution context.
    function _canSetExtension() internal view virtual override returns (bool) {
        return _hasRole(EXTENSION_ROLE, msg.sender);
    }

    /// @dev Checks whether an account has a particular role.
    function _hasRole(bytes32 _role, address _account) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        return data._hasRole[_role][_account];
    }
}
