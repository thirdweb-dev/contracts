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
import "./extension/DropERC1155Storage.sol";

import "../extension/Multicall.sol";

import "../dynamic-contracts/extension/Initializable.sol";
import "../dynamic-contracts/extension/Permissions.sol";
import "../dynamic-contracts/extension/ERC2771ContextUpgradeable.sol";

import "../dynamic-contracts/init/ContractMetadataInit.sol";
import "../dynamic-contracts/init/PlatformFeeInit.sol";
import "../dynamic-contracts/init/RoyaltyInit.sol";
import "../dynamic-contracts/init/PrimarySaleInit.sol";
import "../dynamic-contracts/init/OwnableInit.sol";
import "../dynamic-contracts/init/ERC1155Init.sol";
import "../dynamic-contracts/init/PermissionsEnumerableInit.sol";
import "../dynamic-contracts/init/DefaultOperatorFiltererInit.sol";
import "../dynamic-contracts/init/ReentrancyGuardInit.sol";

contract DropERC1155 is
    Initializable,
    Multicall,
    ERC2771ContextUpgradeable,
    BaseRouter,
    DefaultOperatorFiltererInit,
    ContractMetadataInit,
    PlatformFeeInit,
    RoyaltyInit,
    PrimarySaleInit,
    OwnableInit,
    PermissionsEnumerableInit,
    ERC1155Init
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
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init(_trustedForwarders);
        __ERC1155_init_unchained("");

        _setupContractURI(_contractURI);
        _setupOwner(_defaultAdmin);

        _setupRoles(_defaultAdmin);

        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupPrimarySaleRecipient(_saleRecipient);

        _setupOperatorFilterer();

        DropERC1155Storage.Data storage data = DropERC1155Storage.dropERC1155Storage();
        data.name = _name;
        data.symbol = _symbol;
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
                        ERC 165 / 1155 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    // /// @dev See ERC 165
    // function supportsInterface(bytes4 interfaceId)
    //     public
    //     view
    //     virtual
    //     override(ERC1155Upgradeable, IERC165)
    //     returns (bool)
    // {
    //     return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
    // }

    /*///////////////////////////////////////////////////////////////
                        Contract identifiers
    //////////////////////////////////////////////////////////////*/

    function contractType() external pure returns (bytes32) {
        return bytes32("DropERC1155");
    }

    function contractVersion() external pure returns (uint8) {
        return uint8(5);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a plugin can be set in the given execution context.
    function _canSetExtension() internal view virtual override returns (bool) {
        // bytes32 defaultAdminRole = 0x00;
        // return _hasRole(defaultAdminRole, _msgSender());

        false;
    }

    /// @dev Checks whether an account holds the given role.
    function _hasRole(bytes32 role, address addr) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        return data._hasRole[role][addr];
    }
}
