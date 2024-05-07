// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../eip/interface/IERC4906.sol";

interface INFTMetadata is IERC4906 {
    /// @dev This event emits when the metadata of all tokens are frozen.
    /// While not currently supported by marketplaces, this event allows
    /// future indexing if desired.
    event MetadataFrozen();

    /// @notice Sets the metadata URI for a given NFT.
    function setTokenURI(uint256 _tokenId, string memory _uri) external;

    /// @notice Freezes the metadata URI for a given NFT.
    function freezeMetadata() external;
}
