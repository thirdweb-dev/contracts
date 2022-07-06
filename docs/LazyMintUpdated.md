# LazyMintUpdated





Thirdweb&#39;s `LazyMint` is a contract extension for any base NFT contract. It lets you &#39;lazy mint&#39; any number of NFTs  at once. Here, &#39;lazy mint&#39; means defining the metadata for particular tokenIds of your NFT contract, without actually  minting a non-zero balance of NFTs of those tokenIds.



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





#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | undefined
| _baseURIForTokens | string | undefined
| _data | bytes | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| batchId | uint256 | undefined

### nextTokenIdToLazyMint

```solidity
function nextTokenIdToLazyMint() external view returns (uint256)
```






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

### LazyMint__NotAuthorized

```solidity
error LazyMint__NotAuthorized()
```






### LazyMint__ZeroAmount

```solidity
error LazyMint__ZeroAmount()
```







