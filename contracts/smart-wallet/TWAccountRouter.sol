// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

// Base
import "./BaseRouter.sol";

// Fixed extensions
import "../extension/Multicall.sol";
import "../dynamic-contracts/extension/Initializable.sol";
import "./TWAccountLogic.sol";

// Utils
import "../dynamic-contracts/init/ContractMetadataInit.sol";
import "../dynamic-contracts/init/PermissionsInit.sol";

contract TWAccountRouter is Initializable, Multicall, BaseRouter, TWAccountLogic {
    /*///////////////////////////////////////////////////////////////
                                Constants
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant EXTENSION_ADMIN_ROLE = keccak256("EXTENSION_ADMIN_ROLE");

    /*///////////////////////////////////////////////////////////////
                        Constructor and Initializer
    //////////////////////////////////////////////////////////////*/

    constructor(IEntryPoint _entrypoint) TWAccountLogic(_entrypoint) {}

    function initialize(address _defaultAdmin, string memory _contractURI) public virtual initializer {
        _setupRole(EXTENSION_ADMIN_ROLE, _defaultAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);

        _setupContractURI(_contractURI);
    }

    /*///////////////////////////////////////////////////////////////
                            Public Overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(BaseRouter, ERC1155Receiver)
        returns (bool)
    {
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
