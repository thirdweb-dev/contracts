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





#### Parameters

| Name | Type | Description |
|---|---|---|
| condition  | IClaimCondition.ClaimCondition | undefined |
| resetEligibility  | bool | undefined |

### TokensClaimed

```solidity
event TokensClaimed(address indexed claimer, address indexed receiver, uint256 startTokenId, uint256 quantityClaimed)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| startTokenId  | uint256 | undefined |
| quantityClaimed  | uint256 | undefined |



