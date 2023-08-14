# SharedMetadata









## Methods

### setSharedMetadata

```solidity
function setSharedMetadata(ISharedMetadata.SharedMetadataInfo _metadata) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _metadata | ISharedMetadata.SharedMetadataInfo | undefined |

### sharedMetadata

```solidity
function sharedMetadata() external view returns (string name, string description, string imageURI, string animationURI)
```

Token metadata information




#### Returns

| Name | Type | Description |
|---|---|---|
| name | string | undefined |
| description | string | undefined |
| imageURI | string | undefined |
| animationURI | string | undefined |

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

### SharedMetadataUpdated

```solidity
event SharedMetadataUpdated(string name, string description, string imageURI, string animationURI)
```

Emitted when shared metadata is lazy minted.



#### Parameters

| Name | Type | Description |
|---|---|---|
| name  | string | undefined |
| description  | string | undefined |
| imageURI  | string | undefined |
| animationURI  | string | undefined |



