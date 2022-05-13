# LazyMint









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
function lazyMint(uint256 amount, string baseURIForTokens, bytes encryptedBaseURI) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined
| baseURIForTokens | string | undefined
| encryptedBaseURI | bytes | undefined




