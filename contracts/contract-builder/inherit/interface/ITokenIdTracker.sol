// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

interface ITokenIdTracker {
    function canMintQuantity(uint256 currentTotalMinted, uint256 quantitytoMint) external view returns (bool);
}
