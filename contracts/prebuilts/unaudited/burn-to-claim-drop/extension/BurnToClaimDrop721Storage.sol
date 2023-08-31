// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library BurnToClaimDrop721Storage {
    bytes32 public constant BURN_TO_CLAIM_DROP_721_STORAGE_POSITION = keccak256("burn.to.claim.drop.721.storage");

    struct Data {
        /// @dev Global max total supply of NFTs.
        uint256 maxTotalSupply;
    }

    function burnToClaimDrop721Storage() internal pure returns (Data storage burnToClaimDrop721Data) {
        bytes32 position = BURN_TO_CLAIM_DROP_721_STORAGE_POSITION;
        assembly {
            burnToClaimDrop721Data.slot := position
        }
    }
}
