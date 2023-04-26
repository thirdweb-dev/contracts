// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "../non-upgradeable/Account.sol";
import "../utils/BaseRouter.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

contract DynamicAccount is Account, BaseRouter {
    /*///////////////////////////////////////////////////////////////
                                Constants
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant EXTENSION_ADMIN_ROLE = keccak256("EXTENSION_ADMIN_ROLE");

    /*///////////////////////////////////////////////////////////////
                        Constructor and Initializer
    //////////////////////////////////////////////////////////////*/

    receive() external payable override(Router, Account) {}

    constructor(IEntryPoint _entrypoint) Account(_entrypoint) {}

    function initialize(address _defaultAdmin) public override initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(EXTENSION_ADMIN_ROLE, _defaultAdmin);
    }

    /*///////////////////////////////////////////////////////////////
                            Public Overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(Account, BaseRouter) returns (bool) {
        return
            interfaceId == type(IBaseRouter).interfaceId ||
            interfaceId == type(IRouter).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a extension can be set in the given execution context.
    function _canSetExtension() internal view virtual override returns (bool) {
        return _hasRole(EXTENSION_ADMIN_ROLE, msg.sender);
    }

    /// @dev Checks whether an account holds the given role.
    function _hasRole(bytes32 role, address addr) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        return data._hasRole[role][addr];
    }
}
