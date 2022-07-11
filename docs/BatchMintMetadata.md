# BatchMintMetadata





The `BatchMintMetadata` is a contract extension for any base NFT contract. It lets the smart contract  using this extension set metadata for `n` number of NFTs all at once. This is enabled by storing a single  base URI for a batch of `n` NFTs, where the metadata for each NFT in a relevant batch is `baseURI/tokenId`.



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




