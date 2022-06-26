# ILazyMint





Thirdweb&#39;s `LazyMint` is a contract extension for any base NFT contract. It lets you &#39;lazy mint&#39; any number of NFTs  at once. Here, &#39;lazy mint&#39; means defining the metadata for particular tokenIds of your NFT contract, without actually  minting a non-zero balance of NFTs of those tokenIds.



## Methods

### lazyMint

```solidity
function lazyMint(uint256 amount, string baseURIForTokens, bytes extraData) external nonpayable returns (uint256 batchId)
```

Lazy mints a given amount of NFTs.



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | The number of NFTs to lazy mint.
| baseURIForTokens | string | The base URI for the &#39;n&#39; number of NFTs being lazy minted, where the metadata for each                          of those NFTs is `${baseURIForTokens}/${tokenId}`.
| extraData | bytes | Additional bytes data to be used at the discretion of the consumer of the contract.

#### Returns

| Name | Type | Description |
|---|---|---|
| batchId | uint256 |         A unique integer identifier for the batch of NFTs lazy minted together.




## Errors

### LazyMint__InvalidIndex

```solidity
error LazyMint__InvalidIndex(uint256 index)
```

Emitted when the given index is equal to or higher than total number of batches.



#### Parameters

| Name | Type | Description |
|---|---|---|
| index | uint256 | undefined |

### LazyMint__NoBaseURIForToken

```solidity
error LazyMint__NoBaseURIForToken(uint256 tokenId)
```

Emitted when there&#39;s no Base URI set for the given token ID.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |

### LazyMint__NoBatchIDForToken

```solidity
error LazyMint__NoBatchIDForToken(uint256 tokenId)
```

Emitted when the given token ID doesn&#39;t belong to any batch.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |


