// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "../non-upgradeable/Account.sol";
import "../utils/AccountCore.sol";

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "../utils/BaseRouter.sol";

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

contract DynamicAccount is AccountCore, BaseRouter {
    /*///////////////////////////////////////////////////////////////
                                Constants
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant EXTENSION_ADMIN_ROLE = keccak256("EXTENSION_ADMIN_ROLE");
    address public immutable defaultExtension;

    /*///////////////////////////////////////////////////////////////
                        Constructor and Initializer
    //////////////////////////////////////////////////////////////*/

    receive() external payable override(Router, AccountCore) {}

    constructor(IEntryPoint _entrypoint, address _defaultExtension) AccountCore(_entrypoint) {
        defaultExtension = _defaultExtension;
    }

    function initialize(address _defaultAdmin) public override initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(EXTENSION_ADMIN_ROLE, _defaultAdmin);
    }

    /*///////////////////////////////////////////////////////////////
                            Public Overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IBaseRouter).interfaceId ||
            // interfaceId == type(IRouter).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId;
    }

    /// @dev Returns the extension implementation address stored in router, for the given function.
    function getImplementationForFunction(bytes4 _functionSelector) public view virtual override returns (address) {
        address impl = getExtensionForFunction(_functionSelector).implementation;
        return impl != address(0) ? impl : defaultExtension;
    }

    /*///////////////////////////////////////////////////////////////
                        Internal overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a extension can be set in the given execution context.
    function _canSetExtension() internal view virtual override returns (bool) {
        return _hasRole(EXTENSION_ADMIN_ROLE, msg.sender);
    }
}
