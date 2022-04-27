// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title ERC1155Enumarable Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
interface ERC1155Enumerable {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply(uint256 id) external view returns (uint256);

    /// @notice Returns the next token ID available for minting
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function nextTokenIdToMint() external view returns (uint256);
}
