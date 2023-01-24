// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../eip/interface/IERC1271.sol";
// import "../openzeppelin-presets/utils/cryptography/EIP712.sol";
import "../openzeppelin-presets/utils/cryptography/ECDSA.sol";

abstract contract ERC1271Support {
    using ECDSA for bytes32;

    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    /// @dev Validates a signature.
    function _validateSignature(
        bytes32 _messageHash,
        bytes calldata _signature,
        address _intendedSigner
    ) internal view {
        bool validSignature = false;

        if (_intendedSigner.code.length > 0) {
            validSignature = MAGICVALUE == IERC1271(_intendedSigner).isValidSignature(_messageHash, _signature);
        } else {
            address recoveredSigner = _recoverSigner(_messageHash, _signature);
            validSignature = _intendedSigner == recoveredSigner;
        }

        require(validSignature, "Invalid signer.");
    }

    /// @dev Recovers the signer from a message hash and signature.
    function _recoverSigner(bytes32 _messageHash, bytes memory _signature) internal view virtual returns (address);
}
