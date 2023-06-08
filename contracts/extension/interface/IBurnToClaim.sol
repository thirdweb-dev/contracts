// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

interface IBurnToClaim {
    /// @notice The type of assets that can be burned.
    enum TokenType {
        ERC721,
        ERC1155
    }

    struct BurnToClaimInfo {
        address originContractAddress;
        TokenType tokenType;
        uint256 tokenId; // used only if tokenType is ERC1155
        uint256 mintPriceForNewToken;
        address currency;
    }

    /// @dev Emitted when tokens are burned to claim new tokens
    event TokensBurnedAndClaimed(
        address indexed originContract,
        address indexed tokenOwner,
        uint256 indexed burnTokenId,
        uint256 quantity
    );

    function setBurnToClaimInfo(BurnToClaimInfo calldata burnToClaimInfo) external;
}
