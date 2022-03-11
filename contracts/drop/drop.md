# Drop design document.

This is a live document that explains what the [thirdweb](https://thirdweb.com/) `Drop` smart contracts are, how they work and can be used, and why they are written the way they are.

The document is written for technical and non-technical readers. To ask further questions about any of thirdweb’s `Drop`, please join the [thirdweb discord](https://discord.gg/thirdweb) or create a github issue.

---

## Background

The thirdweb `Drop` contracts are distribution mechanisms for tokens. This distribution mechanism is offered for ERC20, ERC721 and ERC1155 tokens, as `DropERC20`, `DropERC721` and `DropERC1155`.

The `Drop` contracts are meant to be used when the goal of the contract creator is for an audience to come in and claim tokens within certain restrictions e.g. — ‘only addresses in an allowlist can mint tokens’, or ‘minters must pay *x* amount of price in *y* currency to mint’, etc.

The `Drop` contracts let the contract creator establish phases (periods of time), where each phase can specify multiple such restrictions on the minting of tokens during that period of time. We refer to such a phase as a ‘claim condition’.

### Why we’re building `Drop`

We’ve observed that there are largely three distinct contexts under which one mints tokens —

1. Minting tokens for yourself on a contract you own. E.g. a person wants to mint their Twitter profile picture as an NFT.
2. Having an audience mint tokens on a contract you own.
    1. The nature of tokens to be minted by the audience is pre-determined by the contract admin. E.g. a 10k NFT drop where the contents of the NFTs to be minted by the audience is already known and determined by the contract admin before the audience comes in to mint NFTs.
    2. The nature of tokens to be minted by the audience is *not* pre-determined by the contract admin. E.g. a course ‘certificate’ dynamically generated with the name of the course participant, to be minted by the course participant at the time of course completion.

The thirdweb `Token` contracts serve the cases described in (1) and 2(i).

The thirdweb `Drop` contracts serve the case described in 2(ii). They are written to give a contract creator granular control over restrictions around an audience minting tokens from the same contract (or ‘collection’, in the case of NFTs) over an extended period of time.

## Technical Details

The distribution mechanism of `Drop` is as follows — A contract admin establishes a series of ‘claim conditions’. A ‘claim condition’ is a period of time in which accounts can mint tokens on the respective `Drop` contract, within a set of restrictions defined by the ‘claim condition’.

### Claim Conditions

The following makes up a claim condition —

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
| waitTimeInSecondsBetweenClaims | uint256 | The least number of seconds an account must wait after claiming tokens, to be able to claim tokens again. |
| merkleRoot | bytes32 | The allowlist of addresses that can claim tokens under the claim condition.

(Optional) The allowlist may specify the exact amount of tokens that an address in the allowlist is eligible to claim. |
| pricePerToken | uint256 | The price required to pay per token claimed. |
| currency | address | The currency in which the pricePerToken must be paid. |

The parameters that make up a claim condition can be composed in different ways to create specific restrictions around a mint. For example, a single claim condition where:

- `quantityLimitPerTransaction = 5`
- `waitTimeInSecondsBetweenClaims = type(uint256).max`
- `merkleRoot = bytes32(0)`

creates restrictions around a mint, where (1) any wallet can participate in the mint, (2) a wallet can mint at most 5 tokens and (3) a wallet can claim tokens only once.

A `Drop` contract lets a contract admin establish a series of claim conditions, at once. Since each claim condition specifies a `startTime`, a contract admin can establish a series of claim conditions, ordered by their start time, to specify different set of restrictions around minting, during different periods of time.

At any moment, there is only one active claim condition, and an account attempting to mint tokens on the respective `Drop` contract successfully or unsuccessfully, based on whether the account passes the restrictions defined by that moment’s active claim condition.

A `Drop` contract natively keeps track of claim conditions set by a contract admin in a ‘claim conditions list’, which looks as follows —

```solidity
struct ClaimConditionList {
    uint256 currentStartId;
    uint256 count;
    mapping(uint256 => ClaimCondition) phases;
    mapping(uint256 => mapping(address => uint256)) limitLastClaimTimestamp;
    mapping(uint256 => BitMapsUpgradeable.BitMap) limitMerkleProofClaim;
}
```

| Parameter | Description |
| --- | --- |
| currentStartId | The uid for the first claim condition amongst the current set of claim conditions. The uid for each next claim condition is one more than the previous claim condition's uid. |
| count | The total number of phases / claim conditions in the list of claim conditions. |
| phases | The claim conditions at a given uid. Claim conditions are ordered in an ascending order by their startTimestamp. |
| limitLastClaimTimestamp | Map from an account and uid for a claim condition, to the last timestamp at which the account claimed tokens under that claim condition. |
| limitMerkleProofClaim | Map from a claim condition uid to whether an address in an allowlist has already claimed tokens i.e. used their place in the allowlist. |

### Setting claim conditions

In all `Drop` contracts, a contract admin specifies the following when setting claim conditions —

| Parameter | Type | Description |
| --- | --- | --- |
| phases | ClaimCondition[] | Claim conditions in ascending order by startTimestamp. |
| resetClaimEligibility | bool | Whether to reset limitLastClaimTimestamp and limitMerkleProofClaim values when setting new claim conditions. |

When setting claim conditions, any existing set of claim conditions stored in `ClaimConditionsList` are overwritten with the new claim conditions specified in `phases`.

The claim conditions specified in `phases` are expected to be in ordered in ascending order, by their ‘start time’. As a result, only one claim condition is active during at any given time.

Each of the claim conditions specified in `phases` is assigned a unique integer ID. The UID of the first condition in `phases` is stored as the `ClaimConditionList.currentStartId` and each next claim condition’s UID is one more than the previous condition’s UID.

![claim-conditions-diagram-1.png](/assets/claim-conditions-diagram-1.png)

The `resetClaimEligibility` boolean flag determines what UIDs are assigned to the claim conditions specified in `phases`. Since `ClaimConditionList.limitLastClaimTimestamp` and `ClaimConditionList.limitMerkleProofClaim` are both indexed by the UID of claim conditions, this gives a contract admin more granular control over the restrictions that claim conditions can express. We now illustrate this with an example:

Let’s say an existing claim condition **C1** specifies the following restrictions:

- `quantityLimitPerTransaction = 1`
- `waitTimeInSecondsBetweenClaims = type(uint256).max`
- `merkleRoot = bytes32(0)`
- `pricePerToken = 0.1 ether`
- `currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` (i.e. native token of the chain e.g ether for Ethereum mainnet)

At a high level, **C1** expresses the following restrictions on minting — any address can claim at most one token, ever, by paying 0.1 ether in price. 

Let’s say the contract admin wants to increase the price per token from 0.1 ether to 0.2 ether, while ensuring that wallets that have already claimed tokens are not able to claim tokens again. Essentially, the contract admin now wants to instantiate a claim condition **C2** with the following restrictions:

- `quantityLimitPerTransaction = 1`
- `waitTimeInSecondsBetweenClaims = type(uint256).max`
- `merkleRoot = bytes32(0)`
- `pricePerToken = 0.2 ether`
- `currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` (i.e. native token of the chain e.g ether for Ethereum mainnet)

To go from **C1** to **C2** while ensuring that wallets that have already claimed tokens are not able to claim tokens again, the contract admin will set claim conditions while specifying `resetClaimEligibility == false`. As a result, the **C2** will be assigned the same UID as **C1**. Since `ClaimConditionList.limitLastClaimTimestamp` is indexed by the UID of claim conditions, the information of the timestamp at which a wallet claimed tokens during **C1** will not be lost. And so, wallets that claimed tokens during **C1** will now be ineligible to claim tokens during **C2** since the following check will always fail:

```solidity
// pseudo-code
nextValidClaimTimestamp = 
		limitLastClaimTimestamp[UID_of_C2][claimer_address] + C2.waitTimeInSecondsBetweenClaims

require(block.timestamp >= nextValidClaimTimestamp);
```

### EIPs supported / implemented

The distribution mechanism for tokens expressed by thirdweb’s `Drop` is implemented for ERC20, ERC721 and ERC1155 tokens, as `DropERC20`, `DropERC721` and `DropERC1155`.

There are a few key differences between the three implementations —

- `DropERC20` is written for the distribution of completely fungible, ERC20 tokens. On the other hand, `DropERC721` and `DropERC1155` are written for the distribution of NFTs, which requires ‘lazy minting’ i.e. defining the content of the NFTs before an audience comes in to mint them during a claim condition.
- Both `DropERC20` and `DropERC721` maintain a global, contract-wide `ClaimConditionsList` which stores the claim conditions under which tokens can be minted. The `DropERC1155` contract, on the other hand, maintains a `ClaimConditionList` for every integer tokenId that an NFT can assume. And so, a contract admin can set up claim conditions per NFT i.e. per tokenId, in the `DropERC1155` contract.

## Limitations

The distribution mechanism of thirdweb’s `Drop` contracts is vulnerable to [sybil attacks](https://en.wikipedia.org/wiki/Sybil_attack). That is, despite the various ways in which restrictions can be applied to the minting of tokens, some restrictions that claim conditions can express target wallets and not persons.

For example, the restriction `waitTimeInSecondsBetweenClaims` expresses the least amount of time a *wallet* must wait, before claiming tokens again during the respective claim condition. A sophisticated actor may generate multiple wallets to claim tokens in a way that undermine such restrictions, when viewing such restrictions as restrictions on unique persons, and not wallets.

## Authors
- [nkrishang](https://github.com/nkrishang)
- [thirdweb team](https://github.com/thirdweb-dev)