# IDrop









## Methods

### claim

```solidity
function claim(address receiver, uint256 quantity, address currency, uint256 pricePerToken, IDrop.AllowlistProof allowlistProof, bytes data) external payable
```

Lets an account claim a given quantity of NFTs.



#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | The receiver of the NFTs to claim.
| quantity | uint256 | The quantity of NFTs to claim.
| currency | address | The currency in which to pay for the claim.
| pricePerToken | uint256 | The price per token to pay for the claim.
| allowlistProof | IDrop.AllowlistProof | The proof of the claimer&#39;s inclusion in the merkle root allowlist                                        of the claim conditions that apply.
| data | bytes | Arbitrary bytes data that can be leveraged in the implementation of this interface.

### lazyMint

```solidity
function lazyMint(uint256 amount, string baseURIForTokens, bytes extraData) external nonpayable returns (uint256 batchId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined
| baseURIForTokens | string | undefined
| extraData | bytes | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| batchId | uint256 | undefined



## Events

### TokensClaimed

```solidity
event TokensClaimed(uint256 indexed claimConditionIndex, address indexed claimer, address indexed receiver, uint256 startTokenId, uint256 quantityClaimed)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| claimConditionIndex `indexed` | uint256 | undefined |
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| startTokenId  | uint256 | undefined |
| quantityClaimed  | uint256 | undefined |



