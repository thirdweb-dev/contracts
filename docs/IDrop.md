# IDrop









## Methods

### claim

```solidity
function claim(address receiver, uint256 quantity, address currency, uint256 pricePerToken, IDrop.AllowlistProof allowlistProof, bytes data) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | undefined |
| quantity | uint256 | undefined |
| currency | address | undefined |
| pricePerToken | uint256 | undefined |
| allowlistProof | IDrop.AllowlistProof | undefined |
| data | bytes | undefined |

### setClaimConditions

```solidity
function setClaimConditions(IClaimCondition.ClaimCondition[] phases, bool resetClaimEligibility) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| phases | IClaimCondition.ClaimCondition[] | undefined |
| resetClaimEligibility | bool | undefined |



## Events

### ClaimConditionsUpdated

```solidity
event ClaimConditionsUpdated(IClaimCondition.ClaimCondition[] claimConditions, bool resetEligibility)
```



*Emitted when the contract&#39;s claim conditions are updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| claimConditions  | IClaimCondition.ClaimCondition[] | undefined |
| resetEligibility  | bool | undefined |

### TokensClaimed

```solidity
event TokensClaimed(uint256 indexed claimConditionIndex, address indexed claimer, address indexed receiver, uint256 startTokenId, uint256 quantityClaimed)
```



*Emitted when tokens are claimed via `claim`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| claimConditionIndex `indexed` | uint256 | undefined |
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| startTokenId  | uint256 | undefined |
| quantityClaimed  | uint256 | undefined |



## Errors

### Drop__CannotClaimYet

```solidity
error Drop__CannotClaimYet(uint256 blockTimestamp, uint256 startTimestamp, uint256 lastClaimedAt, uint256 nextValidClaimTimestamp)
```

Emitted when the current timestamp is invalid for claim.



#### Parameters

| Name | Type | Description |
|---|---|---|
| blockTimestamp | uint256 | undefined |
| startTimestamp | uint256 | undefined |
| lastClaimedAt | uint256 | undefined |
| nextValidClaimTimestamp | uint256 | undefined |

### Drop__ExceedMaxClaimableSupply

```solidity
error Drop__ExceedMaxClaimableSupply(uint256 supplyClaimed, uint256 maxClaimableSupply)
```

Emitted when claiming given quantity will exceed max claimable supply.



#### Parameters

| Name | Type | Description |
|---|---|---|
| supplyClaimed | uint256 | undefined |
| maxClaimableSupply | uint256 | undefined |

### Drop__InvalidCurrencyOrPrice

```solidity
error Drop__InvalidCurrencyOrPrice(address givenCurrency, address requiredCurrency, uint256 givenPricePerToken, uint256 requiredPricePerToken)
```

Emitted when given currency or price is invalid.



#### Parameters

| Name | Type | Description |
|---|---|---|
| givenCurrency | address | undefined |
| requiredCurrency | address | undefined |
| givenPricePerToken | uint256 | undefined |
| requiredPricePerToken | uint256 | undefined |

### Drop__InvalidQuantity

```solidity
error Drop__InvalidQuantity()
```

Emitted when claiming invalid quantity of tokens.




### Drop__InvalidQuantityProof

```solidity
error Drop__InvalidQuantityProof(uint256 maxQuantityInAllowlist)
```

Emitted when claiming more than allowed quantity in allowlist.



#### Parameters

| Name | Type | Description |
|---|---|---|
| maxQuantityInAllowlist | uint256 | undefined |

### Drop__MaxSupplyClaimedAlready

```solidity
error Drop__MaxSupplyClaimedAlready(uint256 supplyClaimedAlready)
```

Emitted when max claimable supply in given condition is less than supply claimed already.



#### Parameters

| Name | Type | Description |
|---|---|---|
| supplyClaimedAlready | uint256 | undefined |

### Drop__NotAuthorized

```solidity
error Drop__NotAuthorized()
```



*Emitted when an unauthorized caller tries to set claim conditions.*


### Drop__NotInWhitelist

```solidity
error Drop__NotInWhitelist()
```

Emitted when given allowlist proof is invalid.




### Drop__ProofClaimed

```solidity
error Drop__ProofClaimed()
```

Emitted when allowlist spot is already used.





