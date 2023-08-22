# SignatureDrop design document.

This is a live document that explains what the [thirdweb](https://thirdweb.com/) `SignatureDrop` smart contract is, how it works and can be used, and why it is designed the way it is.

The document is written for technical and non-technical readers. To ask further questions about thirdweb’s `SignatureDrop` contract, please join the [thirdweb discord](https://discord.gg/thirdweb) or create a [github issue](https://github.com/thirdweb-dev/contracts/issues).

---

## Background

The thirdweb [`Drop`](https://portal.thirdweb.com/contracts/design/Drop) and [signature minting](https://portal.thirdweb.com/contracts/design/SignatureMint) are distribution mechanisms for tokens. 

The `Drop` contracts are meant to be used when the goal of the contract creator is for an audience to come in and claim tokens within certain restrictions e.g. — ‘only addresses in an allowlist can mint tokens’, or ‘minters must pay **x** amount of price in **y** currency to mint’, etc.

Built-in contracts that implement [signature minting](https://portal.thirdweb.com/contracts/design/SignatureMint) are meant to be used when the restrictions around a wallet's minting tokens are not pre-defined, like in `Drop`. With signature minting, a contract creator can set custom restrictions around a token's minting, such as a price, at the very time that a wallet wants to mint tokens.

The `SignatureDrop` contract supports both distribution mechanisms - of drop and signature minting - in the same contract.

The contract creator 'lazy mints' i.e. defines the content for a batch of NFTs (yet un-minted). An NFT from this batch is distributed to a wallet in one of two ways:
1. claiming tokens under the restrictions defined in the time's active claim phase, as in `Drop`.
2. claiming tokens via a signed payload from a contract admin, as in 'signature minting'.

### How `SignatureDrop` works

![signature-drop-diag.png](/assets/signature-drop-diag.png)

The `SignatureDrop` contract supports both distribution mechanisms - of drop and signature minting - in the same contract. The following is an end-to-end flow, from the contract admin actions, to an end user wallet's actions when minting tokens:

- A contract admin (particularly, a wallet with `MINTER_ROLE`) 'lazy mints' i.e. defines the content for a batch of NFTs. This batch of NFTs can optionally be a batch of [delayed-reveal](https://blog.thirdweb.com/delayed-reveal-nfts) NFTs.
- A contract admin (particularly, a wallet with `DEFAULT_ADMIN_ROLE`) sets a claim phase, which defines restrictions around minting NFTs from the lazy minted batch of NFTs. 
  - **Note:** unlike the `NFT Drop` or `Edition Drop` contracts, where the contract admin can set a series of claim phases at once, the `SignatureDrop` contract lets the contract admin set only *one* claim phase at a time.
- A wallet claims tokens from the batch of lazy minted tokens in one of two ways:
  - claiming tokens under the restrictions defined in the claim phase, as in `Drop`.
  - claiming tokens via a signed payload from a contract admin, as in 'signature minting'.

### Use cases for `SignatureDrop`

We built our `Drop` contracts for the following [reason](https://portal.thirdweb.com/contracts/design/Drop#why-were-building-drop). The limitation of our `Drop` contracts is that all wallets in an audience attempting to claim tokens are subject to the same restrictions in the single, active claim phase at any moment.

In the `SignatureDrop` contract, a wallet can now claim tokens [via a signature](https://portal.thirdweb.com/contracts/design/SignatureMint#background) from an authorized wallet, from the same pool of lazy minted tokens which can be claimed via the `Drop` mechanism. This means a contract owner can now set custom restrictions for a wallet to claim tokens, that may be different from the active claim phase at the time.

An example of using this added feature of the `SignatureDrop` contract is when you want to maintain an allowlist off-chain i.e. not in the claim phase details, which are stored on-chain, and difficult to update once set. The contract's claim phase can define a common set of restrictions that any wallet not in your allowlist will mint tokens under. And using [signature minting](https://portal.thirdweb.com/contracts/design/SignatureMint), you can apply custom restrictions around minting, such as a price, currency and so on, on a per wallet basis, for wallets in your off-chain allowlist.

## Technical Details

`SignatureDrop`  is an ERC721 contract. 

A contract admin can lazy mint tokens, and establish phases for an audience to come claim those tokens under the restrictions of the active phase at the time. On a per wallet basis, a contract admin can let a wallet claim those tokens under restrictions different than the active claim phase, via signature minting.

### Batch upload of NFTs metadata: LazyMint

The contract creator or an address with `MINTER_ROLE` mints *n* NFTs, by providing base URI for the tokens or an encrypted URI.
```solidity
function lazyMint(
	uint256 _amount,
  string calldata _baseURIForTokens,
  bytes calldata _encryptedBaseURI
) external onlyRole(MINTER_ROLE) returns (uint256 batchId)
```
| Parameters | Type | Description |
| --- | --- | --- |
| _amount | uint256 | Amount of tokens to lazy-mint. |
| _baseURIForTokens | string | The metadata URI for the batch of tokens. |
| _encryptedBaseURI | bytes | Encrypted URI for the batch of tokens. |

### Delayed reveal

An account with `MINTER_ROLE` can reveal the URI for a batch of ‘delayed-reveal’ NFTs. The URI can be revealed by calling the following function:
```solidity
function reveal(uint256 _index, bytes calldata _key)
	external
  onlyRole(MINTER_ROLE)
  returns (string memory revealedURI)
```
| Parameters | Type | Description |
| --- | --- | --- |
| _index | uint256 | Index of the batch for which URI is to be revealed. |
| _key | bytes | Key for decrypting the URI. |

### Claiming tokens via signature

An account with `MINTER_ROLE` signs the mint request for a user. The mint request is then submitted for claiming the tokens. The mint request is specified in the following format:
```solidity
struct MintRequest {
	address to;
	address royaltyRecipient;
	uint256 royaltyBps;
	address primarySaleRecipient;
	string uri;
	uint256 quantity;
	uint256 pricePerToken;
	address currency;
	uint128 validityStartTimestamp;
	uint128 validityEndTimestamp;
	bytes32 uid;
}
```
| Parameters | Type | Description |
| --- | --- | --- |
| to | address | The recipient of the tokens to mint. |
| royaltyRecipient | address | The recipient of the minted token's secondary sales royalties. |
| royaltyBps | uint256 | The percentage of the minted token's secondary sales to take as royalties. |
| primarySaleRecipient | address | The recipient of the minted token's primary sales proceeds. |
| uri | string | The metadata URI of the token to mint. |
| quantity | uint256 | The quantity of tokens to mint. |
| pricePerToken | uint256 | The price to pay per quantity of tokens minted. |
| currency | address | The currency in which to pay the price per token minted. |
| validityStartTimestamp | uint128 | The unix timestamp after which the payload is valid. |
| validityEndTimestamp | uint128 | The unix timestamp at which the payload expires. |
| uid | bytes32 | A unique identifier for the payload. |

The authorized external party can mint the tokens by submitting mint-request and contract owner’s signature to the following function:
```solidity
function mintWithSignature(
	ISignatureMintERC721.MintRequest calldata _req, 
	bytes calldata _signature
) external payable
```
| Parameters | Type | Description |
| --- | --- | --- |
| _req | ISignatureMintERC721.MintRequest | Mint request in the format specified above. |
| _signature | bytes | Contact owner’s signature for the mint request. |

### Setting claim conditions

A contract admin (i.e. a holder of `DEFAULT_ADMIN_ROLE`) can set a *single* claim condition; this defines restrictions around claiming from the batch of lazy minted tokens. An active claim condition can be completely overwritten, or updated, by the contract admin. At any moment, there is only one active claim condition.

A claim condition is specified in the following format:
```solidity
struct ClaimCondition {
  uint256 startTimestamp;
  uint256 maxClaimableSupply;
  uint256 supplyClaimed;
  uint256 quantityLimitPerTransaction;
  uint256 waitTimeInSecondsBetweenClaims;
  bytes32 merkleRoot;
  uint256 pricePerToken;
  address currency;
}
```
| Parameters | Type | Description |
| --- | --- | --- |
| startTimestamp | uint256 | The unix timestamp after which the claim condition applies. The same claim condition applies until the startTimestamp of the next claim condition. |
| maxClaimableSupply | uint256 | The maximum total number of tokens that can be claimed under the claim condition. |
| supplyClaimed | uint256 | At any given point, the number of tokens that have been claimed under the claim condition. |
| quantityLimitPerTransaction | uint256 | The maximum number of tokens that can be claimed in a single transaction. |
| waitTimeInSecondsBetweenClaims | uint256 | The least number of seconds an account must wait after claiming tokens, to be able to claim tokens again.. |
| merkleRoot | bytes32 | The allowlist of addresses that can claim tokens under the claim condition. |
| pricePerToken | uint256 | The price required to pay per token claimed. |
| currency | address | The currency in which the pricePerToken must be paid. |

Per wallet restrictions related to the claim condition are stored as follows:
```solidity
/**
  *  @dev Map from an account and uid for a claim condition, to the last timestamp
  *       at which the account claimed tokens under that claim condition.
  */
  mapping(bytes32 => mapping(address => uint256)) private lastClaimTimestamp;

/**
  *  @dev Map from a claim condition uid to whether an address in an allowlist
  *       has already claimed tokens i.e. used their place in the allowlist.
  */
  mapping(bytes32 => BitMapsUpgradeable.BitMap) private usedAllowlistSpot;
```
| Parameters | Type | Description |
| --- | --- | --- |
| lastClaimTimestamp | mapping(bytes32 => mapping(address => uint256)) | Map from an account and uid for a claim condition, to the last timestamp at which the account claimed tokens under that claim condition. |
| usedAllowlistSpot | mapping(bytes32 => BitMapsUpgradeable.BitMap) | Map from a uid for a claim condition to whether an address in an allowlist has already claimed tokens i.e. used their place in the allowlist. |

**Note:** if a claim condition has an allowlist, a wallet can only use their spot in the condition's allowlist *once*. Allowlists can optionally specify the max amount of tokens each wallet in the allowlist can claim. A wallet in such an allowlist, too, can use their allowlist spot only *once*, regardless of the number of tokens they end up claiming.

A contract admin sets claim conditions by calling the following function:
```solidity
/// @dev Lets a contract admin set claim conditions.
function setClaimConditions(
    ClaimCondition calldata _condition,
    bool _resetClaimEligibility,
    bytes memory
) external override;
```
| Parameter | Type | Description |
| --- | --- | --- |
| _condition | ClaimCondition | Defines restrictions around claiming lazy minted tokens. |
| resetClaimEligibility | bool | Whether to reset lastClaimTimestamp and usedAllowlistSpot values when setting a claim conditions. |

You can read into the technical details of setting claim conditions in the [`Drop` design document](https://portal.thirdweb.com/contracts/design/Drop#setting-claim-conditions).


### Claiming tokens via `Drop`
An account can claim the tokens by calling the following function:
```solidity
function claim(
  address _receiver,
  uint256 _quantity,
  address _currency,
  uint256 _pricePerToken,
  AllowlistProof calldata _allowlistProof,
  bytes memory _data
) public payable;
```
| Parameters | Type | Description |
| --- | --- | --- |
| _receiver | address | Mint request in the format specified above. |
| _quantity | uint256 | Contact owner’s signature for the mint request. |
| _currency | address | The currency in which the price must be paid. |
| _pricePerToken | uint256 | The price required to pay per token claimed. |
| _allowlistProof | AllowlistProof | The proof of the claimer's inclusion in the merkle root allowlist of the claim conditions that apply. |
| _data | bytes | Arbitrary bytes data that can be leveraged in the implementation of this interface. |

## Permissions

| Role name | Type (Switch / !Switch) | Purpose |
| -- | -- | -- |
| TRANSFER_ROLE | Switch | Only token transfers to or from role holders are allowed. Minting and burning are not affected. |
| MINTER_ROLE | !Switch | Only MINTER_ROLE holders can sign off on MintRequests and lazy mint tokens. |

What does **Type (Switch / !Switch)** mean?
- **Switch:** If `address(0)` has `ROLE`, then the `ROLE` restrictions don't apply.
- **!Switch:** `ROLE` restrictions always apply.

## Relevant EIPs

| EIP | Link | Relation to SignatureDrop |
| --- | --- | --- |
| 721 | https://eips.ethereum.org/EIPS/eip-721 | `SignatureDrop` is an ERC721 contract. |
| 2981 | https://eips.ethereum.org/EIPS/eip-2981 | `SignatureDrop` implements ERC 2981 for distributing royalties for sales of the wrapped NFTs. |
| 2771 | https://eips.ethereum.org/EIPS/eip-2771 | `SignatureDrop` implements ERC 2771 to support meta-transactions (aka “gasless” transactions). |

## Authors
- [kumaryash90](https://github.com/kumaryash90)
- [thirdweb team](https://github.com/thirdweb-dev)