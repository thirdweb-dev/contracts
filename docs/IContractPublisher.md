# IContractPublisher









## Methods

### addToPublicList

```solidity
function addToPublicList(address publisher, string contractId) external nonpayable
```

Lets an account add a published contract (and all its versions). The account must be approved by the publisher, or be the publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher.
| contractId | string | The identifier for a published contract (that can have multiple verisons).

### getAllPublicPublishedContracts

```solidity
function getAllPublicPublishedContracts() external view returns (struct IContractPublisher.CustomContractInstance[] published)
```

Returns the latest version of all contracts published by a publisher.




#### Returns

| Name | Type | Description |
|---|---|---|
| published | IContractPublisher.CustomContractInstance[] | An array of all contracts published by the publisher.

### getAllPublishedContracts

```solidity
function getAllPublishedContracts(address publisher) external view returns (struct IContractPublisher.CustomContractInstance[] published)
```

Returns the latest version of all contracts published by a publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher.

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IContractPublisher.CustomContractInstance[] | An array of all contracts published by the publisher.

### getPublicId

```solidity
function getPublicId(address publisher, string contractId) external nonpayable returns (uint256 publicId)
```

Returns the public id of a published contract, if it is public.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher.
| contractId | string | The identifier for a published contract (that can have multiple verisons).

#### Returns

| Name | Type | Description |
|---|---|---|
| publicId | uint256 | the public id of a published contract.

### getPublishedContract

```solidity
function getPublishedContract(address publisher, string contractId) external view returns (struct IContractPublisher.CustomContractInstance published)
```

Returns the latest version of a contract published by a publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher.
| contractId | string | The identifier for a published contract (that can have multiple verisons).

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IContractPublisher.CustomContractInstance | The desired contract published by the publisher.

### getPublishedContractVersions

```solidity
function getPublishedContractVersions(address publisher, string contractId) external view returns (struct IContractPublisher.CustomContractInstance[] published)
```

Returns all versions of a published contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher.
| contractId | string | The identifier for a published contract (that can have multiple verisons).

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IContractPublisher.CustomContractInstance[] | The desired contracts published by the publisher.

### publishContract

```solidity
function publishContract(address publisher, string publishMetadataUri, bytes32 bytecodeHash, address implementation, string contractId) external nonpayable
```

Let&#39;s an account publish a contract. The account must be approved by the publisher, or be the publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher.
| publishMetadataUri | string | The IPFS URI of the publish metadata.
| bytecodeHash | bytes32 | The keccak256 hash of the contract bytecode.
| implementation | address | (Optional) An implementation address that proxy contracts / clones can point to. Default value                            if such an implementation does not exist - address(0);
| contractId | string | The identifier for a published contract (that can have multiple verisons).

### removeFromPublicList

```solidity
function removeFromPublicList(address publisher, string contractId) external nonpayable
```

Lets an account remove a published contract (and all its versions). The account must be approved by the publisher, or be the publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher.
| contractId | string | The identifier for a published contract (that can have multiple verisons).

### unpublishContract

```solidity
function unpublishContract(address publisher, string contractId) external nonpayable
```

Lets an account unpublish a contract and all its versions. The account must be approved by the publisher, or be the publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher.
| contractId | string | The identifier for a published contract (that can have multiple verisons).



## Events

### AddedContractToPublicList

```solidity
event AddedContractToPublicList(address indexed publisher, string indexed contractId)
```



*Emitted when a published contract is added to the public list.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher `indexed` | address | undefined |
| contractId `indexed` | string | undefined |

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

### RemovedContractToPublicList

```solidity
event RemovedContractToPublicList(address indexed publisher, string indexed contractId)
```



*Emitted when a published contract is removed from the public list.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher `indexed` | address | undefined |
| contractId `indexed` | string | undefined |



