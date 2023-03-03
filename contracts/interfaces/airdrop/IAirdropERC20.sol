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
    event RecipientsAdded(uint256 startIndex, uint256 endIndex);
    /// @notice Emitted when pending payments are cancelled, and processed count is reset.
    event PaymentsCancelledByAdmin(uint256 startIndex, uint256 endIndex);
    /// @notice Emitted when an airdrop payment is made to a recipient.
    event AirdropPayment(address indexed recipient, uint256 index, bool failed);
    /// @notice Emitted when an airdrop is made using the stateless airdrop function.
    event StatelessAirdrop(address indexed recipient, AirdropContent content, bool failed);

    /**
     *  @notice Details of amount and recipient for airdropped token.
     *
     *  @param tokenAddress The contract address of the tokens to transfer.
     *  @param tokenOwner The owner of the the tokens to transfer.
     *  @param recipient The recipient of the tokens.
     *  @param amount The quantity of tokens to airdrop.
     */
    struct AirdropContent {
        address tokenAddress;
        address tokenOwner;
        address recipient;
        uint256 amount;
    }

    /**
     *  @notice Range of indices of a set of cancelled payments. Each call to cancel payments
     *          stores this range in an array.
     *
     *  @param startIndex First index of the set of cancelled payment indices.
     *  @param endIndex Last index of the set of cancelled payment indices.
     */
    struct CancelledPayments {
        uint256 startIndex;
        uint256 endIndex;
    }

    /// @notice Returns all airdrop payments set up -- pending, processed or failed.
    function getAllAirdropPayments(uint256 startId, uint256 endId)
        external
        view
        returns (AirdropContent[] memory contents);

    /// @notice Returns all pending airdrop payments.
    function getAllAirdropPaymentsPending(uint256 startId, uint256 endId)
        external
        view
        returns (AirdropContent[] memory contents);

    /// @notice Returns all pending airdrop failed.
    function getAllAirdropPaymentsFailed() external view returns (AirdropContent[] memory contents);

    /**
     *  @notice          Lets contract-owner set up an airdrop of ERC20 or native tokens to a list of addresses.
     *
     *  @param _contents  List containing recipients, amounts to airdrop.
     */
    function addRecipients(AirdropContent[] calldata _contents) external payable;

    /**
     *  @notice          Lets contract-owner cancel any pending payments.
     */
    function cancelPendingPayments(uint256 numberOfPaymentsToCancel) external;

    /**
     *  @notice          Lets contract-owner send ERC20 or native tokens to a list of addresses.
     *  @dev             The token-owner should approve target tokens to Airdrop contract,
     *                   which acts as operator for the tokens.
     *
     *  @param paymentsToProcess    The number of airdrop payments to process.
     */
    function processPayments(uint256 paymentsToProcess) external;

    /**
     *  @notice          Lets contract-owner send ERC20 tokens to a list of addresses.
     *  @dev             The token-owner should approve target tokens to Airdrop contract,
     *                   which acts as operator for the tokens.
     *
     *  @param _contents        List containing recipient, tokenId to airdrop.
     */
    function airdrop(AirdropContent[] calldata _contents) external payable;
}
