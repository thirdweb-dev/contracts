# LazyMintERC721









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
function lazyMint(uint256 amount, string baseURIForTokens, bytes extraData) external nonpayable returns (uint256 batchId)
```



*lazy mint a batch of tokens*

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

### nextTokenIdToMint

```solidity
function nextTokenIdToMint() external view returns (uint256)
```



*the next available non-minted token id*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### tokenURI

```solidity
function tokenURI(uint256 _tokenId) external view returns (string)
```



*Returns the URI for a given tokenId*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined



## Events

### TokensLazyMinted

```solidity
event TokensLazyMinted(uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes extraData)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| startTokenId `indexed` | uint256 | undefined |
| endTokenId  | uint256 | undefined |
| baseURI  | string | undefined |
| extraData  | bytes | undefined |



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


