# MockContractPublisher









## Methods

### getAllPublishedContracts

```solidity
function getAllPublishedContracts(address) external pure returns (struct IContractPublisher.CustomContractInstance[] published)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IContractPublisher.CustomContractInstance[] | undefined |

### getPublishedContract

```solidity
function getPublishedContract(address, string) external pure returns (struct IContractPublisher.CustomContractInstance published)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IContractPublisher.CustomContractInstance | undefined |

### getPublishedContractVersions

```solidity
function getPublishedContractVersions(address, string) external pure returns (struct IContractPublisher.CustomContractInstance[] published)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IContractPublisher.CustomContractInstance[] | undefined |

### getPublishedUriFromCompilerUri

```solidity
function getPublishedUriFromCompilerUri(string) external pure returns (string[] publishedMetadataUris)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| publishedMetadataUris | string[] | undefined |

### getPublisherProfileUri

```solidity
function getPublisherProfileUri(address) external pure returns (string uri)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

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
function setPublisherProfileUri(address, string) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | string | undefined |

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





#### Parameters

| Name | Type | Description |
|---|---|---|
| isPaused  | bool | undefined |

### PublisherProfileUpdated

```solidity
event PublisherProfileUpdated(address indexed publisher, string prevURI, string newURI)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher `indexed` | address | undefined |
| prevURI  | string | undefined |
| newURI  | string | undefined |



