# IContractPublisher









## Methods

### getAllPublishedContracts

```solidity
function getAllPublishedContracts(address publisher) external view returns (struct IContractPublisher.CustomContractInstance[] published)
```

Returns the latest version of all contracts published by a publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher. |

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IContractPublisher.CustomContractInstance[] | An array of all contracts published by the publisher. |

### getPublishedContract

```solidity
function getPublishedContract(address publisher, string contractId) external view returns (struct IContractPublisher.CustomContractInstance published)
```

Returns the latest version of a contract published by a publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher. |
| contractId | string | The identifier for a published contract (that can have multiple verisons). |

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IContractPublisher.CustomContractInstance | The desired contract published by the publisher. |

### getPublishedContractVersions

```solidity
function getPublishedContractVersions(address publisher, string contractId) external view returns (struct IContractPublisher.CustomContractInstance[] published)
```

Returns all versions of a published contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher. |
| contractId | string | The identifier for a published contract (that can have multiple verisons). |

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IContractPublisher.CustomContractInstance[] | The desired contracts published by the publisher. |

### getPublishedUriFromCompilerUri

```solidity
function getPublishedUriFromCompilerUri(string compilerMetadataUri) external view returns (string[] publishedMetadataUris)
```

Retrieve the published metadata URI from a compiler metadata URI.



#### Parameters

| Name | Type | Description |
|---|---|---|
| compilerMetadataUri | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| publishedMetadataUris | string[] | undefined |

### getPublisherProfileUri

```solidity
function getPublisherProfileUri(address publisher) external view returns (string uri)
```

Get the publisher profile uri for a given publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| uri | string | undefined |

### publishContract

```solidity
function publishContract(address publisher, string contractId, string publishMetadataUri, string compilerMetadataUri, bytes32 bytecodeHash, address implementation) external nonpayable
```

Let&#39;s an account publish a contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher. |
| contractId | string | The identifier for a published contract (that can have multiple verisons). |
| publishMetadataUri | string | The IPFS URI of the publish metadata. |
| compilerMetadataUri | string | The IPFS URI of the compiler metadata. |
| bytecodeHash | bytes32 | The keccak256 hash of the contract bytecode. |
| implementation | address | (Optional) An implementation address that proxy contracts / clones can point to. Default value                             if such an implementation does not exist - address(0); |

### setPublisherProfileUri

```solidity
function setPublisherProfileUri(address publisher, string uri) external nonpayable
```

Lets an account set its publisher profile uri



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | undefined |
| uri | string | undefined |

### unpublishContract

```solidity
function unpublishContract(address publisher, string contractId) external nonpayable
```

Lets a publisher unpublish a contract and all its versions.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher. |
| contractId | string | The identifier for a published contract (that can have multiple verisons). |



## Events

### ContractPublished

```solidity
event ContractPublished(address indexed operator, address indexed publisher, IContractPublisher.CustomContractInstance publishedContract)
```



*Emitted when a contract is published.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| operator `indexed` | address | undefined |
| publisher `indexed` | address | undefined |
| publishedContract  | IContractPublisher.CustomContractInstance | undefined |

### ContractUnpublished

```solidity
event ContractUnpublished(address indexed operator, address indexed publisher, string indexed contractId)
```



*Emitted when a contract is unpublished.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| operator `indexed` | address | undefined |
| publisher `indexed` | address | undefined |
| contractId `indexed` | string | undefined |

### Paused

```solidity
event Paused(bool isPaused)
```



*Emitted when the registry is paused.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| isPaused  | bool | undefined |

### PublisherProfileUpdated

```solidity
event PublisherProfileUpdated(address indexed publisher, string prevURI, string newURI)
```



*Emitted when a publisher updates their profile URI.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher `indexed` | address | undefined |
| prevURI  | string | undefined |
| newURI  | string | undefined |



