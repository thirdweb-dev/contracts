// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../IThirdwebContract.sol";
import "../IThirdwebPlatformFee.sol";
import "../IThirdwebPrimarySale.sol";
import "./IDropClaimCondition.sol";

/**
 *  `LazyMintERC20` is an ERC 20 contract.
 *
 *  The module admin can create claim conditions with non-overlapping time windows,
 *  and accounts can claim the tokens, in a given time window, according to restrictions
 *  defined in that time window's claim conditions.
 */

interface IDropERC20 is
    IThirdwebContract,
    IThirdwebPrimarySale,
    IThirdwebPlatformFee,
    IERC20Upgradeable,
    IDropClaimCondition
{
    /// @dev Emitted when tokens are claimed.
    event TokensClaimed(
        uint256 indexed claimConditionIndex,
        address indexed claimer,
        address indexed receiver,
        uint256 quantityClaimed
    );

    /// @dev Emitted when new claim conditions are set.
    event ClaimConditionsUpdated(ClaimCondition[] claimConditions);

    /// @dev Emitted when a new sale recipient is set.
    event PrimarySaleRecipientUpdated(address indexed recipient);

    /// @dev Emitted when fee on primary sales is updated.
    event PlatformFeeInfoUpdated(address platformFeeRecipient, uint256 platformFeeBps);

    /// @dev Emitted when a max total supply is set for a token.
    event MaxTotalSupplyUpdated(uint256 maxTotalSupply);

    /// @dev Emitted when a wallet claim count is updated.
    event WalletClaimCountUpdated(address indexed wallet, uint256 count);

    /// @dev Emitted when the max wallet claim count is updated.
    event MaxWalletClaimCountUpdated(uint256 count);

    /**
     *  @notice Lets an account claim a given quantity of tokens.
     *
     *  @param _receiver The receiver of the NFTs to claim.
     *  @param _quantity The quantity of tokens to claim.
     *  @param _currency The currency in which to pay for the claim.
     *  @param _pricePerToken The price per token to pay for the claim.
     *  @param _proofs The proof required to prove the account's inclusion in the merkle root whitelist
     *                 of the mint conditions that apply.
     *  @param _proofMaxQuantityPerTransaction The maximum claim quantity per transactions that included in the merkle proof.
     */
    function claim(
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) external payable;

    /**
     *  @notice Lets a module admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.
     *
     *  @param _phases Mint conditions in ascending order by `startTimestamp`.
     *  @param _resetLimitRestriction To reset claim phases limit restriction.
     */
    function setClaimConditions(ClaimCondition[] calldata _phases, bool _resetLimitRestriction) external;
}
