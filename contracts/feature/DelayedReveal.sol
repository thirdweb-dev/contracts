// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IDelayedReveal.sol";

abstract contract DelayedReveal is IDelayedReveal {
    /// @dev Mapping from id of a batch of tokens => to encrypted base URI for the respective batch of tokens.
    mapping(uint256 => bytes) public encryptedBaseURI;

    /// @dev Sets the encrypted baseURI for a batch of tokenIds.
    function _setEncryptedBaseURI(uint256 _batchId, bytes memory _encryptedBaseURI) internal {
        encryptedBaseURI[_batchId] = _encryptedBaseURI;
    }

    /// @dev Returns the decrypted i.e. revealed URI for a batch of tokens.
    function getRevealURI(uint256 _batchId, bytes calldata _key) public returns (string memory revealedURI) {
        bytes memory encryptedURI = encryptedBaseURI[_batchId];
        require(encryptedURI.length != 0, "nothing to reveal.");

        revealedURI = string(encryptDecrypt(encryptedURI, _key));

        // yash - added this, and removed view mutability
        delete encryptedBaseURI[_batchId];
    }

    /// @dev See: https://ethereum.stackexchange.com/questions/69825/decrypt-message-on-chain
    function encryptDecrypt(bytes memory data, bytes calldata key) public pure override returns (bytes memory result) {
        // Store data length on stack for later use
        uint256 length = data.length;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Set result to free memory pointer
            result := mload(0x40)
            // Increase free memory pointer by lenght + 32
            mstore(0x40, add(add(result, length), 32))
            // Set result length
            mstore(result, length)
        }

        // Iterate over the data stepping by 32 bytes
        for (uint256 i = 0; i < length; i += 32) {
            // Generate hash of the key and offset
            bytes32 hash = keccak256(abi.encodePacked(key, i));

            bytes32 chunk;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // Read 32-bytes data chunk
                chunk := mload(add(data, add(i, 32)))
            }
            // XOR the chunk with hash
            chunk ^= hash;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // Write 32-byte encrypted chunk
                mstore(add(result, add(i, 32)), chunk)
            }
        }
    }

    /// @dev Returns whether the relvant batch of NFTs is subject to a delayed reveal.
    function isEncryptedBatch(uint256 _batchId) public view returns (bool) {
        return encryptedBaseURI[_batchId].length > 0;
    }
}
