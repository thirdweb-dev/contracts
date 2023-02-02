// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/**
 *  Thirdweb's `Airdrop` contracts provide a lightweight and easy to use mechanism
 *  to drop tokens.
 *
 *  `AirdropERC1155` contract is an airdrop contract for ERC1155 tokens. It follows a
 *  push mechanism for transfer of tokens to intended recipients.
 */

interface IAirdropERC1155 {
    /// @notice Emitted when airdrop recipients are uploaded to the contract.
    event RecipientsAdded(AirdropContent[] _contents);
    /// @notice Emitted when pending payments are cancelled, and processed count is reset.
    event PaymentsResetByAdmin();
    /// @notice Emitted when an airdrop payment is made to a recipient.
    event AirdropPayment(address indexed recipient, AirdropContent content, bool failed);
    /// @notice Emitted when an airdrop is made using the stateless airdrop function.
    event StatelessAirdrop(address indexed recipient, AirdropContent content, bool failed);

    /**
     *  @notice Details of amount and recipient for airdropped token.
     *
     *  @param tokenAddress The contract address of the tokens to transfer.
     *  @param tokenOwner The owner of the the tokens to transfer.
     *  @param recipient The recipient of the tokens.
     *  @param tokenId ID of the ERC1155 token being airdropped.
     *  @param amount The quantity of tokens to airdrop.
     */
    struct AirdropContent {
        address tokenAddress;
        address tokenOwner;
        address recipient;
        uint256 tokenId;
        uint256 amount;
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

    /// @notice Returns all pending airdrop processed.
    function getAllAirdropPaymentsProcessed(uint256 startId, uint256 endId)
        external
        view
        returns (AirdropContent[] memory contents);

    /// @notice Returns all pending airdrop failed.
    function getAllAirdropPaymentsFailed() external view returns (AirdropContent[] memory contents);

    /**
     *  @notice          Lets contract-owner set up an airdrop of ERC1155 tokens to a list of addresses.
     *  @dev             The token-owner should approve target tokens to Airdrop contract,
     *                   which acts as operator for the tokens.
     *
     *  @param _contents  List containing recipients, tokenIds to airdrop.
     */
    function addRecipients(AirdropContent[] calldata _contents) external;

    /**
     *  @notice          Lets contract-owner cancel any pending payments.
     */
    function resetRecipients() external;

    /**
     *  @notice          Lets contract-owner set up an airdrop of ERC1155 tokens to a list of addresses.
     *  @dev             The token-owner should approve target tokens to Airdrop contract,
     *                   which acts as operator for the tokens.
     *
     *  @param paymentsToProcess    The number of airdrop payments to process.
     */
    function processPayments(uint256 paymentsToProcess) external;

    /**
     *  @notice          Lets contract-owner send ERC1155 tokens to a list of addresses.
     *  @dev             The token-owner should approve target tokens to Airdrop contract,
     *                   which acts as operator for the tokens.
     *
     *  @param _contents        List containing recipient, tokenId to airdrop.
     */
    function airdrop(AirdropContent[] calldata _contents) external;
}
