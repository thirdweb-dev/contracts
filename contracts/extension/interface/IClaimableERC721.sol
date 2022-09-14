// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IClaimableERC721 {
    /// @dev Emitted when tokens are claimed
    event TokensClaimed(
        address indexed claimer,
        address indexed receiver,
        uint256 indexed startTokenId,
        uint256 quantityClaimed
    );

    /**
     *  @notice          Lets an address claim multiple lazy minted NFTs at once to a recipient.
     *                   Contract creators should override this function to create custom logic for claiming,
     *                   for e.g. price collection, allowlist, max quantity, etc.
     *
     *  @dev             The logic in the `verifyClaim` function determines whether the caller is authorized to mint NFTs.
     *
     *  @param _receiver  The recipient of the NFT to mint.
     *  @param _quantity  The number of NFTs to mint.
     */
    function claim(address _receiver, uint256 _quantity) external payable;

    /**
     *  @notice          Override this function to add logic for claim verification, based on conditions
     *                   such as allowlist, price, max quantity etc.
     *
     *  @dev             Checks a request to claim NFTs against a custom condition.
     *
     *  @param _claimer   Caller of the claim function.
     *  @param _quantity  The number of NFTs being claimed.
     */
    function verifyClaim(address _claimer, uint256 _quantity) external view;
}
