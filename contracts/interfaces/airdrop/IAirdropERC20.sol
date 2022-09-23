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
    /// @notice Emitted when airdrop recipients are uploaded to the contract.
    event RecipientsAdded(AirdropContent[] _contents);
    /// @notice Emitted when an airdrop payment is made to a recipient.
    event AirdropPayment(address indexed recipient, AirdropContent content);

    /**
     *  @notice Details of amount and recipient for airdropped token.
     *
     *  @param recipient The recipient of the tokens.
     *  @param amount The quantity of tokens to airdrop.
     */
    struct AirdropContent {
        address tokenAddress;
        address tokenOwner;
        address recipient;
        uint256 amount;
    }

    /// @notice Returns all airdrop payments set up -- pending, processed or failed.
    function getAllAirdropPayments() external view returns (AirdropContent[] memory contents);

    /// @notice Returns all pending airdrop payments.
    function getAllAirdropPaymentsPending() external view returns (AirdropContent[] memory contents);

    /// @notice Returns all pending airdrop processed.
    function getAllAirdropPaymentsProcessed() external view returns (AirdropContent[] memory contents);

    /// @notice Returns all pending airdrop failed.
    function getAllAirdropPaymentsFailed() external view returns (AirdropContent[] memory contents);

    /**
     *  @notice          Lets contract-owner set up an airdrop of ERC20 or native tokens to a list of addresses.
     *
     *  @param _contents  List containing recipients, amounts to airdrop.
     */
    function addAirdropRecipients(AirdropContent[] calldata _contents) external payable;

    /**
     *  @notice          Lets contract-owner send ERC20 or native tokens to a list of addresses.
     *  @dev             The token-owner should approve target tokens to Airdrop contract,
     *                   which acts as operator for the tokens.
     *
     *  @param paymentsToProcess    The number of airdrop payments to process.
     */
    function airdrop(uint256 paymentsToProcess) external;
}
