// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/ISignatureAction.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

abstract contract SignatureActionUpgradeable is EIP712Upgradeable, ISignatureAction {
    using ECDSAUpgradeable for bytes32;

    bytes32 private constant TYPEHASH =
        keccak256("GenericRequest(uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid,bytes data)");

    /// @dev Mapping from a signed request UID => whether the request is processed.
    mapping(bytes32 => bool) private executed;

    function __SignatureAction_init() internal onlyInitializing {
        __EIP712_init("SignatureAction", "1");
    }

    function __SignatureAction_init_unchained() internal onlyInitializing {}

    /// @dev Verifies that a request is signed by an authorized account.
    function verify(GenericRequest calldata _req, bytes calldata _signature)
        public
        view
        override
        returns (bool success, address signer)
    {
        signer = _recoverAddress(_req, _signature);
        success = !executed[_req.uid] && _isAuthorizedSigner(signer);
    }

    /// @dev Returns whether a given address is authorized to sign requests.
    function _isAuthorizedSigner(address _signer) internal view virtual returns (bool);

    /// @dev Verifies a request and marks the request as processed.
    function _processRequest(GenericRequest calldata _req, bytes calldata _signature)
        internal
        returns (address signer)
    {
        bool success;
        (success, signer) = verify(_req, _signature);

        if (!success) {
            revert("Invalid req");
        }

        if (_req.validityStartTimestamp > block.timestamp || block.timestamp > _req.validityEndTimestamp) {
            revert("Req expired");
        }

        executed[_req.uid] = true;
    }

    /// @dev Returns the address of the signer of the request.
    function _recoverAddress(GenericRequest calldata _req, bytes calldata _signature) internal view returns (address) {
        return _hashTypedDataV4(keccak256(_encodeRequest(_req))).recover(_signature);
    }

    /// @dev Encodes a request for recovery of the signer in `recoverAddress`.
    function _encodeRequest(GenericRequest calldata _req) internal pure returns (bytes memory) {
        return
            abi.encode(
                TYPEHASH,
                _req.validityStartTimestamp,
                _req.validityEndTimestamp,
                _req.uid,
                keccak256(_req.data)
            );
    }
}
