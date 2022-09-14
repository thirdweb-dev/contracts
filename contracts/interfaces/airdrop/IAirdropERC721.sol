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
     *  @notice          Lets contract-owner send ERC721 tokens to a list of addresses.
     *  @dev             The token-owner should approve target tokens to Airdrop contract,
     *                   which acts as operator for the tokens.
     *
     *  @param _tokenAddress    Contract address of ERC721 tokens to air-drop.
     *  @param _tokenOwner      Address from which to transfer tokens.
     *  @param _recipients      List of recipient addresses for the air-drop.
     *  @param _tokenIds        ERC721 token-Ids of tokens to drop.
     */
    function airdrop(
        address _tokenAddress,
        address _tokenOwner,
        address[] memory _recipients,
        uint256[] memory _tokenIds
    ) external;
}
