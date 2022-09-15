// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/**
 *  Thirdweb's `Airdrop` contracts provide a lightweight and easy to use mechanism
 *  to drop tokens.
 *
 *  `AirdropERC721Claimable` contract is an airdrop contract for ERC721 tokens. It follows a
 *  pull mechanism for transfer of tokens, where allowlisted recipients can claim tokens from
 *  the contract.
 */

interface IAirdropERC721Claimable {
    /// @dev Emitted when tokens are claimed.
    event TokensClaimed(address indexed claimer, address indexed receiver, uint256 quantityClaimed);

    /**
     *  @notice Lets an account claim a given quantity of NFTs.
     *
     *  @param receiver                       The receiver of the NFTs to claim.
     *  @param quantity                       The quantity of NFTs to claim.
     *  @param proofs                         The proof of the claimer's inclusion in the merkle root allowlist
     *                                        of the claim conditions that apply.
     *  @param proofMaxQuantityForWallet      The maximum number of NFTs an address included in an
     *                                        allowlist can claim.
     */
    function claim(
        address receiver,
        uint256 quantity,
        bytes32[] calldata proofs,
        uint256 proofMaxQuantityForWallet
    ) external;
}
