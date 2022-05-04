// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title ERC1155 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
interface IERC1155Enumerable {
    /// @notice Returns the next token ID available for minting
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function nextTokenIdToMint() external view returns (uint256);
}
