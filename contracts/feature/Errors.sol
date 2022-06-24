// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/*///////////////////////////////////////////////////////////////
                        Common Errors
//////////////////////////////////////////////////////////////*/

error NotAuthorized__SetContractURI();
error NotAuthorized__SetOwner();
error NotAuthorized__SetPlatformFeeInfo();
error NotAuthorized__SetPrimarySaleRecipient();
error NotAuthorized__SetRoyaltyInfo();
error NotAuthorized();

/*///////////////////////////////////////////////////////////////
                        Contract Specific Errors
//////////////////////////////////////////////////////////////*/

/*
* Contract: DelayedReveal.sol
*/
error DelayedReveal__NothingToReveal();

/*
* Contract: DropSinglePhase.sol
*/
error DropSinglePhase__InvalidCurrencyOrPrice();
error DropSinglePhase__InvalidQuantity();
error DropSinglePhase__ExceedMaxClaimableSupply();
error DropSinglePhase__CannotClaimYet();
error DropSinglePhase__NotInWhitelist();
error DropSinglePhase__ProofClaimed();
error DropSinglePhase__InvalidQuantityProof();

/*
* Contract: Permissions.sol
*/
error Permissions__CanOnlyRenounceForSelf();

/*
* Contract: PlatformFee.sol
*/
error PlatformFee__ExceedsMaxBps();

/*
* Contract: Royalty.sol
*/
error Royalty__ExceedsMaxBps();

/*
* Contract: SignatureMintERC721.sol
* Contract: SignatureMintERC721Upgradeable.sol
*/
error SignatureMintERC721__InvalidRequest();
error SignatureMintERC721__RequestExpired();
error SignatureMintERC721Upgradeable__InvalidRequest();
error SignatureMintERC721Upgradeable__RequestExpired();

/*
* Contract: SignatureDrop.sol
*/
error SignatureDrop__NotEnoughMintedTokens();
error SignatureDrop__MintingZeroTokens();
error SignatureDrop__ZeroAmount();
error SignatureDrop__MustSendTotalPrice();
error SignatureDrop__NotTransferRole();