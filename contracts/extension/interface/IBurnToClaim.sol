// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

interface IBurnToClaim {
    /// @notice The type of assets that can be burned.
    enum TokenType {
        ERC721,
        ERC1155
    }

    /**
     *  @notice Configuration for burning tokens to claim new tokens.
     *
     *  @param originContractAddress The address of the contract that the tokens are burned from.
     *  @param tokenType The type of token to burn.
     *  @param tokenId The token ID of the token to burn. Only used if tokenType is ERC1155.
     *  @param mintPriceForNewToken The price to mint a new token.
     *  @param currency The currency to pay the mint price in.
     */
    struct BurnToClaimInfo {
        address originContractAddress;
        TokenType tokenType;
        uint256 tokenId; // used only if tokenType is ERC1155
        uint256 mintPriceForNewToken;
        address currency;
    }

    /// @notice Emitted when tokens are burned to claim new tokens
    event TokensBurnedAndClaimed(
        address indexed originContract,
        address indexed tokenOwner,
        uint256 indexed burnTokenId,
        uint256 quantity
    );

    /**
     *  @notice Sets the configuration for burning tokens to claim new tokens.
     *  @param burnToClaimInfo The configuration for burning tokens to claim new tokens.
     */
    function setBurnToClaimInfo(BurnToClaimInfo calldata burnToClaimInfo) external;
}
