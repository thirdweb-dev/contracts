// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../inherit/internal/LazyMintInternal.sol";
import "../../lib/TWStrings.sol";

contract TokenUriLazyMintExt is LazyMintInternal {
    using TWStrings for uint256;

    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        (uint256 batchId, ) = _getBatchId(_tokenId);
        string memory batchUri = _getBaseURI(_tokenId);

        if (_isEncryptedBatch(batchId)) {
            return string(abi.encodePacked(batchUri, "0"));
        } else {
            return string(abi.encodePacked(batchUri, _tokenId.toString()));
        }
    }
}
