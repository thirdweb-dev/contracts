# ISharedMetadataBatch

*thirdweb*







## Methods

### deleteSharedMetadata

```solidity
function deleteSharedMetadata(bytes32 id) external nonpayable
```

Delete shared metadata for NFTs



#### Parameters

| Name | Type | Description |
|---|---|---|
| id | bytes32 | UID for the metadata |

### getAllSharedMetadata

```solidity
function getAllSharedMetadata() external view returns (struct ISharedMetadataBatch.SharedMetadataWithId[] metadata)
```

Get all shared metadata




#### Returns

| Name | Type | Description |
|---|---|---|
| metadata | ISharedMetadataBatch.SharedMetadataWithId[] | array of all shared metadata |

### setSharedMetadata

```solidity
function setSharedMetadata(ISharedMetadataBatch.SharedMetadataInfo metadata, bytes32 id) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| metadata | ISharedMetadataBatch.SharedMetadataInfo | undefined |
| id | bytes32 | undefined |



## Events

### SharedMetadataDeleted

```solidity
event SharedMetadataDeleted(bytes32 indexed id)
```

Emitted when shared metadata is deleted.



#### Parameters

| Name | Type | Description |
|---|---|---|
| id `indexed` | bytes32 | undefined |

### SharedMetadataUpdated

```solidity
event SharedMetadataUpdated(bytes32 indexed id, string name, string description, string imageURI, string animationURI)
```

Emitted when shared metadata is lazy minted.



#### Parameters

| Name | Type | Description |
|---|---|---|
| id `indexed` | bytes32 | undefined |
| name  | string | undefined |
| description  | string | undefined |
| imageURI  | string | undefined |
| animationURI  | string | undefined |



