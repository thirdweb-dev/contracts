# Drop









## Methods

### claim

```solidity
function claim(address _receiver, uint256 _quantity, address _currency, uint256 _pricePerToken, IDrop.AllowlistProof _allowlistProof, bytes _data) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _receiver | address | undefined |
| _quantity | uint256 | undefined |
| _currency | address | undefined |
| _pricePerToken | uint256 | undefined |
| _allowlistProof | IDrop.AllowlistProof | undefined |
| _data | bytes | undefined |

### claimCondition

```solidity
function claimCondition() external view returns (uint256 currentStartId, uint256 count)
```



*The active conditions for claiming tokens.*


#### Returns

| Name | Type | Description |
|---|---|---|
| currentStartId | uint256 | undefined |
| count | uint256 | undefined |

### getActiveClaimConditionId

```solidity
function getActiveClaimConditionId() external view returns (uint256)
```



*At any given moment, returns the uid for the active claim condition.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getClaimConditionById

```solidity
function getClaimConditionById(uint256 _conditionId) external view returns (struct IClaimCondition.ClaimCondition condition)
```



*Returns the claim condition at the given uid.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _conditionId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| condition | IClaimCondition.ClaimCondition | undefined |

### getSupplyClaimedByWallet

```solidity
function getSupplyClaimedByWallet(uint256 _conditionId, address _claimer) external view returns (uint256 supplyClaimedByWallet)
```



*Returns the supply claimed by claimer for a given conditionId.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _conditionId | uint256 | undefined |
| _claimer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| supplyClaimedByWallet | uint256 | undefined |

### setClaimConditions

```solidity
function setClaimConditions(IClaimCondition.ClaimCondition[] _conditions, bool _resetClaimEligibility) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _conditions | IClaimCondition.ClaimCondition[] | undefined |
| _resetClaimEligibility | bool | undefined |

### verifyClaim

```solidity
function verifyClaim(uint256 _conditionId, address _claimer, uint256 _quantity, address _currency, uint256 _pricePerToken, IDrop.AllowlistProof _allowlistProof) external view returns (bool isOverride)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _conditionId | uint256 | undefined |
| _claimer | address | undefined |
| _quantity | uint256 | undefined |
| _currency | address | undefined |
| _pricePerToken | uint256 | undefined |
| _allowlistProof | IDrop.AllowlistProof | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| isOverride | bool | undefined |



## Events

### ClaimConditionsUpdated

```solidity
event ClaimConditionsUpdated(IClaimCondition.ClaimCondition[] claimConditions, bool resetEligibility)
```

Emitted when the contract&#39;s claim conditions are updated.



#### Parameters

| Name | Type | Description |
|---|---|---|
| claimConditions  | IClaimCondition.ClaimCondition[] | undefined |
| resetEligibility  | bool | undefined |

### TokensClaimed

```solidity
event TokensClaimed(uint256 indexed claimConditionIndex, address indexed claimer, address indexed receiver, uint256 startTokenId, uint256 quantityClaimed)
```

Emitted when tokens are claimed via `claim`.



#### Parameters

| Name | Type | Description |
|---|---|---|
| claimConditionIndex `indexed` | uint256 | undefined |
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| startTokenId  | uint256 | undefined |
| quantityClaimed  | uint256 | undefined |



