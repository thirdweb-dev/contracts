# INFTMetadata









## Methods

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

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```



*Returns true if this contract implements the interface defined by `interfaceId`. See the corresponding [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified) to learn more about how these ids are created. This function call must use less than 30 000 gas.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| interfaceId | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |



## Events

### BatchMetadataUpdate

```solidity
event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _fromTokenId  | uint256 | undefined |
| _toTokenId  | uint256 | undefined |

### MetadataUpdate

```solidity
event MetadataUpdate(uint256 _tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId  | uint256 | undefined |



