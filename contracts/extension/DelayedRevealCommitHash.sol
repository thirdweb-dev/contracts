// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IDelayedRevealCommitHash.sol";

/**
 *  Thirdweb's `DelayedRevealCommitHash` is a contract extension for base NFT contracts. It lets you create batches of
 *  'delayed-reveal' NFTs by (1) first publishing the provenance hash of the NFTs' metadata URI, and later (2) publishing
 *  the metadata URI of the NFTs which is checked against the provenance hash.
 */

abstract contract DelayedRevealCommitHash is IDelayedRevealCommitHash {
    /**
     *  @notice Returns the provenance hash of NFTs grouped by the given identifier.
     *
     *  @dev Mapping from 'largest tokenId of a batch of delayed-reveal tokens with
     *       the same baseURI' to provenance hash for the respective batch of tokens.
     **/
    mapping(uint256 => bytes32) public baseURICommitHash;

    /// @dev Sets the encrypted baseURI for a batch of tokenIds.
    function _setBaseURICommitHash(uint256 _identifier, bytes32 _baseURICommitHash) internal {
        baseURICommitHash[_identifier] = _baseURICommitHash;
    }

    /// @dev Returns whether the relvant batch of NFTs is subject to a delayed reveal.
    function isDelayedRevealBatch(uint256 _identifier) public view returns (bool) {
        return baseURICommitHash[_identifier] != "";
    }

    /**
     *  @notice Returns whether the given metadata URI is the true metadata URI associated with the provenance hash
     *          for NFTs grouped by the given identifier.
     */
    function isValidBaseURI(uint256 _identifier, bytes32 _salt, string calldata _baseURIToReveal) public view returns (bool) {
        bytes32 commitHash = baseURICommitHash[_identifier];
        require(commitHash != "", "Nothing to reveal.");

        bytes32 inputURIInfoHash = keccak256(abi.encodePacked(_baseURIToReveal, _salt));
        return inputURIInfoHash == commitHash;
    }
}
