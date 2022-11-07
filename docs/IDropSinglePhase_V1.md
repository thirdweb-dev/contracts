# IDropSinglePhase_V1









## Methods

### claim

```solidity
function claim(address receiver, uint256 quantity, address currency, uint256 pricePerToken, IDropSinglePhase_V1.AllowlistProof allowlistProof, bytes data) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | undefined |
| quantity | uint256 | undefined |
| currency | address | undefined |
| pricePerToken | uint256 | undefined |
| allowlistProof | IDropSinglePhase_V1.AllowlistProof | undefined |
| data | bytes | undefined |

### setClaimConditions

```solidity
function setClaimConditions(IClaimCondition_V1.ClaimCondition phase, bool resetClaimEligibility) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| phase | IClaimCondition_V1.ClaimCondition | undefined |
| resetClaimEligibility | bool | undefined |



## Events

### ClaimConditionUpdated

```solidity
event ClaimConditionUpdated(IClaimCondition_V1.ClaimCondition condition, bool resetEligibility)
```



*Emitted when the contract&#39;s claim conditions are updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| condition  | IClaimCondition_V1.ClaimCondition | undefined |
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



