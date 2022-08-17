# IContractMetadataRegistry









## Methods

### registerMetadata

```solidity
function registerMetadata(address contractAddress, string metadataUri) external nonpayable
```



*Records `metadataUri` as metadata for the contract at `contractAddress`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| contractAddress | address | undefined |
| metadataUri | string | undefined |



## Events

### MetadataRegistered

```solidity
event MetadataRegistered(address indexed contractAddress, string metadataUri)
```



*Emitted when a contract metadata is registered*

#### Parameters

| Name | Type | Description |
|---|---|---|
| contractAddress `indexed` | address | undefined |
| metadataUri  | string | undefined |



