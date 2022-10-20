# IDrop1155





The interface `IDrop1155` is written for thirdweb&#39;s &#39;Drop&#39; contracts, which are distribution mechanisms for tokens.  An authorized wallet can set a series of claim conditions, ordered by their respective `startTimestamp`.  A claim condition defines criteria under which accounts can mint tokens. Claim conditions can be overwritten  or added to by the contract admin. At any moment, there is only one active claim condition.



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

Emitted when the contract&#39;s claim conditions are updated.



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

Emitted when tokens are claimed.



#### Parameters

| Name | Type | Description |
|---|---|---|
| claimConditionIndex `indexed` | uint256 | undefined |
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |
| quantityClaimed  | uint256 | undefined |



