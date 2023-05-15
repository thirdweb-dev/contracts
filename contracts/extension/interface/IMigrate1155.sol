// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

interface IMigrate1155 {
    /// @dev Emitted when tokens are migrated
    event TokensMigrated(address indexed migratedFrom, address indexed owner, uint256 indexed tokenId, uint256 amount);

    function migrateTokens(uint256 tokenId, uint256 amount) external;

    function setTokensEligibleForMigration(uint256[] calldata tokenIds) external;
}
