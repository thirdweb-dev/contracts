# IDrop1155









## Methods

### claim

```solidity
function claim(address receiver, uint256 tokenId, uint256 quantity, address currency, uint256 pricePerToken, IDrop1155.AllowlistProof allowlistProof, bytes data) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | undefined |
| tokenId | uint256 | undefined |
| quantity | uint256 | undefined |
| currency | address | undefined |
| pricePerToken | uint256 | undefined |
| allowlistProof | IDrop1155.AllowlistProof | undefined |
| data | bytes | undefined |

### setClaimConditions

```solidity
function setClaimConditions(uint256 tokenId, IClaimCondition.ClaimCondition[] phases, bool resetClaimEligibility) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |
| phases | IClaimCondition.ClaimCondition[] | undefined |
| resetClaimEligibility | bool | undefined |



## Events

### ClaimConditionsUpdated

```solidity
event ClaimConditionsUpdated(uint256 indexed tokenId, IClaimCondition.ClaimCondition[] claimConditions, bool resetEligibility)
```



*Emitted when the contract&#39;s claim conditions are updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId `indexed` | uint256 | undefined |
| claimConditions  | IClaimCondition.ClaimCondition[] | undefined |
| resetEligibility  | bool | undefined |

### TokensClaimed

```solidity
event TokensClaimed(uint256 indexed claimConditionIndex, address indexed claimer, address indexed receiver, uint256 tokenId, uint256 quantityClaimed)
```



*Emitted when tokens are claimed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| claimConditionIndex `indexed` | uint256 | undefined |
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |
| quantityClaimed  | uint256 | undefined |



