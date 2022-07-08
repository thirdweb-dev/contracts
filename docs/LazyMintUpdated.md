# LazyMintUpdated





The `LazyMint` is a contract extension for any base NFT contract. It lets you &#39;lazy mint&#39; any number of NFTs  at once. Here, &#39;lazy mint&#39; means defining the metadata for particular tokenIds of your NFT contract, without actually  minting a non-zero balance of NFTs of those tokenIds.



## Methods

### getBaseURICount

```solidity
function getBaseURICount() external view returns (uint256)
```



*Returns the number of batches of tokens having the same baseURI.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### getBatchIdAtIndex

```solidity
function getBatchIdAtIndex(uint256 _index) external view returns (uint256)
```



*Returns the id for the batch of tokens the given tokenId belongs to.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _index | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### lazyMint

```solidity
function lazyMint(uint256 _amount, string _baseURIForTokens, bytes _data) external nonpayable returns (uint256 batchId)
```

Lets an authorized address lazy mint a given amount of NFTs.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | The number of NFTs to lazy mint.
| _baseURIForTokens | string | The base URI for the &#39;n&#39; number of NFTs being lazy minted, where the metadata for each                           of those NFTs is `${baseURIForTokens}/${tokenId}`.
| _data | bytes | Additional bytes data to be used at the discretion of the consumer of the contract.

#### Returns

| Name | Type | Description |
|---|---|---|
| batchId | uint256 |          A unique integer identifier for the batch of NFTs lazy minted together.

### nextTokenIdToLazyMint

```solidity
function nextTokenIdToLazyMint() external view returns (uint256)
```

The tokenId assigned to the next new NFT to be lazy minted.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined



## Events

### TokensLazyMinted

```solidity
event TokensLazyMinted(uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes data)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| startTokenId `indexed` | uint256 | undefined |
| endTokenId  | uint256 | undefined |
| baseURI  | string | undefined |
| data  | bytes | undefined |



## Errors

### BatchMintMetadata__InvalidIndex

```solidity
error BatchMintMetadata__InvalidIndex(uint256 index)
```

Emitted when the given index is equal to or higher than total number of batches.



#### Parameters

| Name | Type | Description |
|---|---|---|
| index | uint256 | undefined |

### BatchMintMetadata__NoBaseURIForToken

```solidity
error BatchMintMetadata__NoBaseURIForToken(uint256 tokenId)
```

Emitted when there&#39;s no Base URI set for the given token ID.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |

### BatchMintMetadata__NoBatchIDForToken

```solidity
error BatchMintMetadata__NoBatchIDForToken(uint256 tokenId)
```

Emitted when the given token ID doesn&#39;t belong to any batch.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |

### LazyMint__NotAuthorized

```solidity
error LazyMint__NotAuthorized()
```



*Emitted when an unauthorized address attempts to lazy mint tokens.*


### LazyMint__ZeroAmount

```solidity
error LazyMint__ZeroAmount()
```



*Emitted when caller attempts to lazy mint zero tokens.*


