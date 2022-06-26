# IDropSinglePhase









## Methods

### claim

```solidity
function claim(address receiver, uint256 quantity, address currency, uint256 pricePerToken, IDropSinglePhase.AllowlistProof allowlistProof, bytes data) external payable
```

Lets an account claim a given quantity of NFTs.



#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | The receiver of the NFTs to claim.
| quantity | uint256 | The quantity of NFTs to claim.
| currency | address | The currency in which to pay for the claim.
| pricePerToken | uint256 | The price per token to pay for the claim.
| allowlistProof | IDropSinglePhase.AllowlistProof | The proof of the claimer&#39;s inclusion in the merkle root allowlist                                        of the claim conditions that apply.
| data | bytes | Arbitrary bytes data that can be leveraged in the implementation of this interface.

### setClaimConditions

```solidity
function setClaimConditions(IClaimCondition.ClaimCondition phase, bool resetClaimEligibility) external nonpayable
```

Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.



#### Parameters

| Name | Type | Description |
|---|---|---|
| phase | IClaimCondition.ClaimCondition | Claim condition to set.
| resetClaimEligibility | bool | Whether to reset `limitLastClaimTimestamp` and `limitMerkleProofClaim` values when setting new                                  claim conditions.



## Events

### ClaimConditionUpdated

```solidity
event ClaimConditionUpdated(IClaimCondition.ClaimCondition condition, bool resetEligibility)
```



*Emitted when the contract&#39;s claim conditions are updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| condition  | IClaimCondition.ClaimCondition | undefined |
| resetEligibility  | bool | undefined |

### TokensClaimed

```solidity
event TokensClaimed(address indexed claimer, address indexed receiver, uint256 indexed startTokenId, uint256 quantityClaimed)
```



*Emitted when tokens are claimed via `claim`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| startTokenId `indexed` | uint256 | undefined |
| quantityClaimed  | uint256 | undefined |



## Errors

### DropSinglePhase__CannotClaimYet

```solidity
error DropSinglePhase__CannotClaimYet(uint256 blockTimestamp, uint256 startTimestamp, uint256 lastClaimedAt, uint256 nextValidClaimTimestamp)
```

Emitted when the current timestamp is invalid for claim.



#### Parameters

| Name | Type | Description |
|---|---|---|
| blockTimestamp | uint256 | undefined |
| startTimestamp | uint256 | undefined |
| lastClaimedAt | uint256 | undefined |
| nextValidClaimTimestamp | uint256 | undefined |

### DropSinglePhase__ExceedMaxClaimableSupply

```solidity
error DropSinglePhase__ExceedMaxClaimableSupply(uint256 supplyClaimed, uint256 maxClaimableSupply)
```

Emitted when claiming given quantity will exceed max claimable supply.



#### Parameters

| Name | Type | Description |
|---|---|---|
| supplyClaimed | uint256 | undefined |
| maxClaimableSupply | uint256 | undefined |

### DropSinglePhase__InvalidCurrencyOrPrice

```solidity
error DropSinglePhase__InvalidCurrencyOrPrice(address givenCurrency, address requiredCurrency, uint256 givenPricePerToken, uint256 requiredPricePerToken)
```

Emitted when given currency or price is invalid.



#### Parameters

| Name | Type | Description |
|---|---|---|
| givenCurrency | address | undefined |
| requiredCurrency | address | undefined |
| givenPricePerToken | uint256 | undefined |
| requiredPricePerToken | uint256 | undefined |

### DropSinglePhase__InvalidQuantity

```solidity
error DropSinglePhase__InvalidQuantity()
```

Emitted when claiming invalid quantity of tokens.




### DropSinglePhase__InvalidQuantityProof

```solidity
error DropSinglePhase__InvalidQuantityProof(uint256 maxQuantityInAllowlist)
```

Emitted when claiming more than allowed quantity in allowlist.



#### Parameters

| Name | Type | Description |
|---|---|---|
| maxQuantityInAllowlist | uint256 | undefined |

### DropSinglePhase__MaxSupplyClaimedAlready

```solidity
error DropSinglePhase__MaxSupplyClaimedAlready(uint256 supplyClaimedAlready)
```

Emitted when max claimable supply in given condition is less than supply claimed already.



#### Parameters

| Name | Type | Description |
|---|---|---|
| supplyClaimedAlready | uint256 | undefined |

### DropSinglePhase__NotAuthorized

```solidity
error DropSinglePhase__NotAuthorized()
```



*Emitted when an unauthorized caller tries to set claim conditions.*


### DropSinglePhase__NotInWhitelist

```solidity
error DropSinglePhase__NotInWhitelist()
```

Emitted when given allowlist proof is invalid.




### DropSinglePhase__ProofClaimed

```solidity
error DropSinglePhase__ProofClaimed()
```

Emitted when allowlist spot is already used.





