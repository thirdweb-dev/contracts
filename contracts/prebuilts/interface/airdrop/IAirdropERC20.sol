// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/**
 *  Thirdweb's `Airdrop` contracts provide a lightweight and easy to use mechanism
 *  to drop tokens.
 *
 *  `AirdropERC20` contract is an airdrop contract for ERC20 tokens. It follows a
 *  push mechanism for transfer of tokens to intended recipients.
 */

interface IAirdropERC20 {
    /// @notice Emitted when an airdrop fails for a recipient address.
    event AirdropFailed(
        address indexed tokenAddress,
        address indexed tokenOwner,
        address indexed recipient,
        uint256 amount
    );

    /**
     *  @notice Details of amount and recipient for airdropped token.
     *
     *  @param recipient The recipient of the tokens.
     *  @param amount The quantity of tokens to airdrop.
     */
    struct AirdropContent {
        address recipient;
        uint256 amount;
    }

    /**
     *  @notice          Lets contract-owner send ERC20 tokens to a list of addresses.
     *  @dev             The token-owner should approve target tokens to Airdrop contract,
     *                   which acts as operator for the tokens.
     *
     *  @param tokenAddress    The contract address of the tokens to transfer.
     *  @param tokenOwner      The owner of the tokens to transfer.
     *  @param contents        List containing recipient, tokenId to airdrop.
     */
    function airdropERC20(
        address tokenAddress,
        address tokenOwner,
        AirdropContent[] calldata contents
    ) external payable;
}
