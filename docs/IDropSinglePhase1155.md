# IDropSinglePhase1155









## Methods

### claim

```solidity
function claim(address receiver, uint256 tokenId, uint256 quantity, address currency, uint256 pricePerToken, IDropSinglePhase1155.AllowlistProof allowlistProof, bytes data) external payable
```

Lets an account claim a given quantity of NFTs.



#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | The receiver of the NFT to claim.
| tokenId | uint256 | The tokenId of the NFT to claim.
| quantity | uint256 | The quantity of the NFT to claim.
| currency | address | The currency in which to pay for the claim.
| pricePerToken | uint256 | The price per token to pay for the claim.
| allowlistProof | IDropSinglePhase1155.AllowlistProof | The proof of the claimer&#39;s inclusion in the merkle root allowlist                                        of the claim conditions that apply.
| data | bytes | Arbitrary bytes data that can be leveraged in the implementation of this interface.

### setClaimConditions

```solidity
function setClaimConditions(uint256 tokenId, IClaimCondition.ClaimCondition phase, bool resetClaimEligibility) external nonpayable
```

Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | The tokenId for which to set the relevant claim condition.
| phase | IClaimCondition.ClaimCondition | Claim condition to set.
| resetClaimEligibility | bool | Whether to reset `limitLastClaimTimestamp` and `limitMerkleProofClaim` values when setting new                                  claim conditions.



## Events

### ClaimConditionUpdated

```solidity
event ClaimConditionUpdated(uint256 indexed tokenId, IClaimCondition.ClaimCondition condition, bool resetEligibility)
```



*Emitted when the contract&#39;s claim conditions are updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId `indexed` | uint256 | undefined |
| condition  | IClaimCondition.ClaimCondition | undefined |
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



