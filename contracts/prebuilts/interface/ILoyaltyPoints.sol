// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface ILoyaltyPoints {
    /// @dev Emitted when an account with MINTER_ROLE mints an NFT.
    event TokensMinted(address indexed mintedTo, uint256 quantityMinted);

    /// @notice Returns the total tokens minted to `owner` in the contract's lifetime.
    function getTotalMintedInLifetime(address owner) external view returns (uint256);

    /**
     *  @notice Lets an account with MINTER_ROLE mint an NFT.
     *
     *  @param to The address to mint tokens to.
     *  @param amount The amount of tokens to mint.
     */
    function mintTo(address to, uint256 amount) external;

    /// @notice Let's a loyalty pointsß owner or approved operator cancel the given amount of loyalty points.
    function cancel(address owner, uint256 amount) external;

    /// @notice Let's an approved party revoke a holder's loyalty points (no approval needed).
    function revoke(address owner, uint256 amount) external;
}
