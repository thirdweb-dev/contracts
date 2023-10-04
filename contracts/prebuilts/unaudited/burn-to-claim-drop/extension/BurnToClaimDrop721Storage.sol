// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library BurnToClaimDrop721Storage {
    /// @custom:storage-location erc7201:burn.to.claim.drop.721.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("burn.to.claim.drop.721.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant BURN_TO_CLAIM_DROP_721_STORAGE_POSITION =
        0x3107fcf7768de14f3c3441e6960e7a1659b448f798b4e6665bf2dc61db3ea300;

    struct Data {
        /// @dev Global max total NFTs that can be minted.
        uint256 maxTotalMinted;
    }

    function burnToClaimDrop721Storage() internal pure returns (Data storage burnToClaimDrop721Data) {
        bytes32 position = BURN_TO_CLAIM_DROP_721_STORAGE_POSITION;
        assembly {
            burnToClaimDrop721Data.slot := position
        }
    }
}
