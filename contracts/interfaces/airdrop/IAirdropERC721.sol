// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/**
 *  Thirdweb's `Airdrop` contracts provide a lightweight and easy to use mechanism
 *  to drop tokens.
 *
 *  `AirdropERC721` contract is an airdrop contract for ERC721 tokens. It follows a
 *  push mechanism for transfer of tokens to intended recipients.
 */

interface IAirdropERC721 {
    /**
     *  @notice Details of amount and recipient for airdropped token.
     *
     *  @param recipient The recipient of the tokens.
     *  @param tokenId ID of the ERC721 token being airdropped.
     */
    struct AirdropContent {
        address recipient;
        uint256 tokenId;
    }

    /**
     *  @notice          Lets contract-owner send ERC721 tokens to a list of addresses.
     *  @dev             The token-owner should approve target tokens to Airdrop contract,
     *                   which acts as operator for the tokens.
     *
     *  @param _tokenAddress    Contract address of ERC721 tokens to air-drop.
     *  @param _tokenOwner      Address from which to transfer tokens.
     *  @param _contents        List containing recipients, tokenIds to airdrop.
     */
    function airdrop(
        address _tokenAddress,
        address _tokenOwner,
        AirdropContent[] calldata _contents
    ) external;
}
