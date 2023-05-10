// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.11;

import "./UserOperation.sol";
import "../../openzeppelin-presets/utils/cryptography/EIP712.sol";

abstract contract AccountSigUtil is EIP712 {
    using ECDSA for bytes32;

    bytes32 private constant TYPEHASH =
        keccak256(
            "UserOperation(address sender,uint256 nonce,bytes initCode,bytes callData,uint256 callGasLimit,uint256 verificationGasLimit,uint256 preVerificationGas,uint256 maxFeePerGas,uint256 maxPriorityFeePerGas,bytes paymasterAndData,bytes signature)"
        );

    /// @dev Verifies that a UserOp is signed by an authorized account.
    function _verifySignature(UserOperation calldata _req) public view returns (bool success) {
        address signer = _recoverAddress(_req, _req.signature);
        success = _isAuthorizedSigner(signer);
    }

    /// @dev Returns whether a given address is authorized to sign requests.
    function _isAuthorizedSigner(address _signer) internal view virtual returns (bool);

    /// @dev Returns the address of the signer of the request.
    function _recoverAddress(UserOperation calldata _req, bytes calldata _signature) internal view returns (address) {
        return _hashTypedDataV4(keccak256(_encodeRequest(_req))).recover(_signature);
    }

    /// @dev Encodes a request for recovery of the signer in `recoverAddress`.
    function _encodeRequest(UserOperation calldata _req) internal pure returns (bytes memory) {
        return
            abi.encode(
                TYPEHASH,
                _req.sender,
                _req.nonce,
                keccak256(_req.initCode),
                keccak256(_req.callData),
                _req.callGasLimit,
                _req.verificationGasLimit,
                _req.preVerificationGas,
                _req.maxFeePerGas,
                _req.maxPriorityFeePerGas,
                keccak256(_req.paymasterAndData),
                keccak256(bytes("")) // A user signs a user op with an empty signature field
            );
    }
}
