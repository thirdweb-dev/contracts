# LazyMintWithTier





The `LazyMint` is a contract extension for any base NFT contract. It lets you &#39;lazy mint&#39; any number of NFTs  at once. Here, &#39;lazy mint&#39; means defining the metadata for particular tokenIds of your NFT contract, without actually  minting a non-zero balance of NFTs of those tokenIds.



## Methods

### getBaseURICount

```solidity
function getBaseURICount() external view returns (uint256)
```

Returns the count of batches of NFTs.

*Each batch of tokens has an in ID and an associated `baseURI`.                  See {batchIds}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getBatchIdAtIndex

```solidity
function getBatchIdAtIndex(uint256 _index) external view returns (uint256)
```

Returns the ID for the batch of tokens the given tokenId belongs to.

*See {getBaseURICount}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _index | uint256 | ID of a token. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getMetadataForAllTiers

```solidity
function getMetadataForAllTiers() external view returns (struct LazyMintWithTier.TierMetadata[] metadataForAllTiers)
```

Returns all metadata for all tiers created on the contract.




#### Returns

| Name | Type | Description |
|---|---|---|
| metadataForAllTiers | LazyMintWithTier.TierMetadata[] | undefined |

### lazyMint

```solidity
function lazyMint(uint256 _amount, string _baseURIForTokens, string _tier, bytes _data) external nonpayable returns (uint256 batchId)
```

Lets an authorized address lazy mint a given amount of NFTs.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | The number of NFTs to lazy mint. |
| _baseURIForTokens | string | The base URI for the &#39;n&#39; number of NFTs being lazy minted, where the metadata for each                           of those NFTs is `${baseURIForTokens}/${tokenId}`. |
| _tier | string | undefined |
| _data | bytes | Additional bytes data to be used at the discretion of the consumer of the contract. |

#### Returns

| Name | Type | Description |
|---|---|---|
| batchId | uint256 |          A unique integer identifier for the batch of NFTs lazy minted together. |



## Events

### TokensLazyMinted

```solidity
event TokensLazyMinted(string indexed tier, uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes encryptedBaseURI)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tier `indexed` | string | undefined |
| startTokenId `indexed` | uint256 | undefined |
| endTokenId  | uint256 | undefined |
| baseURI  | string | undefined |
| encryptedBaseURI  | bytes | undefined |



