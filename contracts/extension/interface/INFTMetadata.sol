// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../eip/interface/IERC4906.sol";

interface INFTMetadata is IERC4906 {
    /// @notice Sets the metadata URI for a given NFT.
    function setTokenURI(uint256 _tokenId, string memory _uri) external;
}
