// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IExtensionRegistrySig.sol";
import "./extension/EIP712.sol";

library ExtensionRegistrySigStorage {
    bytes32 public constant EXTENSION_REGISTRY_SIG_STORAGE_POSITION = keccak256("extension.registry.sig.storage");

    struct Data {
        mapping(bytes32 => bool) executed;
    }

    function extensionRegistrySigStorage() internal pure returns (Data storage extensionRegistrySigData) {
        bytes32 position = EXTENSION_REGISTRY_SIG_STORAGE_POSITION;
        assembly {
            extensionRegistrySigData.slot := position
        }
    }
}

abstract contract ExtensionRegistrySig is EIP712, IExtensionRegistrySig {
    using ECDSA for bytes32;

    bytes32 private constant TYPEHASH =
        keccak256(
            "ExtensionUpdateRequest(address caller,uint256 updateType,bytes32 uid,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
        );

    /// @dev Mapping from a signed request UID => whether the request is processed.
    mapping(bytes32 => bool) private executed;

    function __ExtensionRegistrySig_init() internal onlyInitializing {
        __EIP712_init("ExtensionRegistrySig", "1");
    }

    function __ExtensionRegistrySig_init_unchained() internal onlyInitializing {}

    /// @dev Verifies that a request is signed by an authorized account.
    function verify(ExtensionUpdateRequest calldata _req, bytes calldata _signature)
        public
        view
        override
        returns (bool success, address signer)
    {
        ExtensionRegistrySigStorage.Data storage data = ExtensionRegistrySigStorage.extensionRegistrySigStorage();

        signer = _recoverAddress(_req, _signature);
        success = !data.executed[_req.uid] && _isAuthorizedSigner(signer);
    }

    /// @dev Returns whether a given address is authorized to sign requests.
    function _isAuthorizedSigner(address _signer) internal view virtual returns (bool);

    /// @dev Verifies a request and marks the request as processed.
    function _processRequest(ExtensionUpdateRequest calldata _req, bytes calldata _signature)
        internal
        returns (address signer)
    {
        bool success;
        (success, signer) = verify(_req, _signature);

        if (!success) {
            revert("ExtensionRegistrySig: invalid request.");
        }

        if (_req.validityStartTimestamp > block.timestamp || block.timestamp > _req.validityEndTimestamp) {
            revert("ExtensionRegistrySig: request expired.");
        }

        ExtensionRegistrySigStorage.Data storage data = ExtensionRegistrySigStorage.extensionRegistrySigStorage();
        data.executed[_req.uid] = true;
    }

    /// @dev Returns the address of the signer of the request.
    function _recoverAddress(ExtensionUpdateRequest calldata _req, bytes calldata _signature)
        internal
        view
        returns (address)
    {
        return _hashTypedDataV4(keccak256(_encodeRequest(_req))).recover(_signature);
    }

    /// @dev Encodes a request for recovery of the signer in `recoverAddress`.
    function _encodeRequest(ExtensionUpdateRequest calldata _req) internal pure returns (bytes memory) {
        return
            abi.encode(
                TYPEHASH,
                _req.caller,
                _req.updateType,
                _req.uid,
                _req.validityStartTimestamp,
                _req.validityEndTimestamp
            );
    }
}
