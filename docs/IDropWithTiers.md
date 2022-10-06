# IDropWithTiers









## Methods

### claim

```solidity
function claim(address receiver, uint256 quantity, address currency, uint256 pricePerToken, IDropWithTiers.AllowlistProof allowlistProof, bytes data) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | undefined |
| quantity | uint256 | undefined |
| currency | address | undefined |
| pricePerToken | uint256 | undefined |
| allowlistProof | IDropWithTiers.AllowlistProof | undefined |
| data | bytes | undefined |

### setClaimConditions

```solidity
function setClaimConditions(IDropWithTiers.ClaimConditionForTier condition, bool _resetClaimEligibility) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| condition | IDropWithTiers.ClaimConditionForTier | undefined |
| _resetClaimEligibility | bool | undefined |



## Events

### ClaimConditionUpdated

```solidity
event ClaimConditionUpdated(IDropWithTiers.ClaimConditionForTier condition, bool resetEligibility)
```



*Emitted when the contract&#39;s claim conditions are updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| condition  | IDropWithTiers.ClaimConditionForTier | undefined |
| resetEligibility  | bool | undefined |

### TokensClaimed

```solidity
event TokensClaimed(address indexed claimer, address indexed receiver, string indexed tier, uint256 startTokenId, uint256 quantityClaimed)
```



*Emitted when tokens are claimed via `claim`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| tier `indexed` | string | undefined |
| startTokenId  | uint256 | undefined |
| quantityClaimed  | uint256 | undefined |



