# ILazyMintWithTier





Thirdweb&#39;s `LazyMintWithTier` is a contract extension for any base NFT contract. It lets you &#39;lazy mint&#39; any number of NFTs  at once, for a particular tier. Here, &#39;lazy mint&#39; means defining the metadata for particular tokenIds of your NFT contract,  without actually minting a non-zero balance of NFTs of those tokenIds.



## Methods

### lazyMint

```solidity
function lazyMint(uint256 amount, string baseURIForTokens, string tier, bytes extraData) external nonpayable returns (uint256 batchId)
```

Lazy mints a given amount of NFTs.



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | The number of NFTs to lazy mint. |
| baseURIForTokens | string | The base URI for the &#39;n&#39; number of NFTs being lazy minted, where the metadata for each                          of those NFTs is `${baseURIForTokens}/${tokenId}`. |
| tier | string | The tier for which these tokens are being lazy mitned. Here, `tier` is a unique string label                          that is used to group together different batches of lazy minted tokens under a common category. |
| extraData | bytes | Additional bytes data to be used at the discretion of the consumer of the contract. |

#### Returns

| Name | Type | Description |
|---|---|---|
| batchId | uint256 |         A unique integer identifier for the batch of NFTs lazy minted together. |



## Events

### TokensLazyMinted

```solidity
event TokensLazyMinted(string indexed tier, uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes encryptedBaseURI)
```



*Emitted when tokens are lazy minted.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tier `indexed` | string | undefined |
| startTokenId `indexed` | uint256 | undefined |
| endTokenId  | uint256 | undefined |
| baseURI  | string | undefined |
| encryptedBaseURI  | bytes | undefined |



