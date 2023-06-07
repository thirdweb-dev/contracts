# NFTMetadata









## Methods

### _getTokenURI

```solidity
function _getTokenURI(uint256 _tokenId) external view returns (string)
```

Returns the metadata URI for a given NFT.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### setTokenURI

```solidity
function setTokenURI(uint256 _tokenId, string _uri) external nonpayable
```

Sets the metadata URI for a given NFT.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined |
| _uri | string | undefined |



## Events

### TokenURIUpdated

```solidity
event TokenURIUpdated(uint256 indexed tokenId, string prevURI, string newURI)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId `indexed` | uint256 | undefined |
| prevURI  | string | undefined |
| newURI  | string | undefined |



