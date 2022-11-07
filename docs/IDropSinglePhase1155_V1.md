# IDropSinglePhase1155_V1









## Methods

### claim

```solidity
function claim(address receiver, uint256 tokenId, uint256 quantity, address currency, uint256 pricePerToken, IDropSinglePhase1155_V1.AllowlistProof allowlistProof, bytes data) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | undefined |
| tokenId | uint256 | undefined |
| quantity | uint256 | undefined |
| currency | address | undefined |
| pricePerToken | uint256 | undefined |
| allowlistProof | IDropSinglePhase1155_V1.AllowlistProof | undefined |
| data | bytes | undefined |

### setClaimConditions

```solidity
function setClaimConditions(uint256 tokenId, IClaimCondition_V1.ClaimCondition phase, bool resetClaimEligibility) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |
| phase | IClaimCondition_V1.ClaimCondition | undefined |
| resetClaimEligibility | bool | undefined |



## Events

### ClaimConditionUpdated

```solidity
event ClaimConditionUpdated(uint256 indexed tokenId, IClaimCondition_V1.ClaimCondition condition, bool resetEligibility)
```



*Emitted when the contract&#39;s claim conditions are updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId `indexed` | uint256 | undefined |
| condition  | IClaimCondition_V1.ClaimCondition | undefined |
| resetEligibility  | bool | undefined |

### TokensClaimed

```solidity
event TokensClaimed(address indexed claimer, address indexed receiver, uint256 indexed tokenId, uint256 quantityClaimed)
```



*Emitted when tokens are claimed via `claim`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId `indexed` | uint256 | undefined |
| quantityClaimed  | uint256 | undefined |



