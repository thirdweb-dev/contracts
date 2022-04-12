# IByocRegistry









## Methods

### approveOperator

```solidity
function approveOperator(address operator, bool toApprove) external nonpayable
```

Lets a publisher (caller) approve an operator to publish / unpublish contracts on their behalf.



#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | The address of the operator who publishes/unpublishes on behalf of the publisher.
| toApprove | bool | whether to an operator to publish / unpublish contracts on the publisher&#39;s behalf.

### getAllPublishedContracts

```solidity
function getAllPublishedContracts(address publisher) external view returns (struct IByocRegistry.CustomContract[] published)
```

Returns all contracts published by a publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher.

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IByocRegistry.CustomContract[] | An array of all contracts published by the publisher.

### getPublishedContract

```solidity
function getPublishedContract(address publisher, uint256 contractId) external view returns (struct IByocRegistry.CustomContract published)
```

Returns a given contract published by a publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher.
| contractId | uint256 | The unique integer identifier of the published contract. (publisher address, contractId) =&gt; published contract.

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IByocRegistry.CustomContract | The desired contract published by the publisher.

### getPublishedContractGroup

```solidity
function getPublishedContractGroup(address publisher, bytes32 groupId) external view returns (struct IByocRegistry.CustomContract[] published)
```

Returns a group of contracts published by a publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher.
| groupId | bytes32 | The identifier for a group of published contracts.

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IByocRegistry.CustomContract[] | The desired contracts published by the publisher.

### isApprovedByPublisher

```solidity
function isApprovedByPublisher(address publisher, address operator) external view returns (bool isApproved)
```

Returns whether a publisher has approved an operator to publish / unpublish contracts on their behalf.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher.
| operator | address | The address of the operator who publishes/unpublishes on behalf of the publisher.

#### Returns

| Name | Type | Description |
|---|---|---|
| isApproved | bool | Whether the publisher has approved the operator to publish / unpublish contracts on their behalf.

### publishContract

```solidity
function publishContract(address publisher, string publishMetadataUri, bytes32 bytecodeHash, address implementation, bytes32 groupId) external nonpayable returns (uint256 contractId)
```

Let&#39;s an account publish a contract. The account must be approved by the publisher, or be the publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher.
| publishMetadataUri | string | The IPFS URI of the publish metadata.
| bytecodeHash | bytes32 | The keccak256 hash of the contract bytecode.
| implementation | address | (Optional) An implementation address that proxy contracts / clones can point to. Default value                        if such an implementation does not exist - address(0);
| groupId | bytes32 | The identifier for the group of published contracts that the contract-to-publish belongs to.

#### Returns

| Name | Type | Description |
|---|---|---|
| contractId | uint256 | The unique integer identifier of the published contract. (publisher address, contractId) =&gt; published contract.

### unpublishContract

```solidity
function unpublishContract(address publisher, uint256 contractId) external nonpayable
```

Let&#39;s an account unpublish a contract. The account must be approved by the publisher, or be the publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher. 
| contractId | uint256 | The unique integer identifier of the published contract. (publisher address, contractId) =&gt; published contract.



## Events

### Approved

```solidity
event Approved(address indexed publisher, address indexed operator, bool isApproved)
```



*Emitted when a publisher&#39;s approval of an operator is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher `indexed` | address | undefined |
| operator `indexed` | address | undefined |
| isApproved  | bool | undefined |

### ContractPublished

```solidity
event ContractPublished(address indexed operator, address indexed publisher, uint256 indexed contractId, IByocRegistry.CustomContract publishedContract)
```



*Emitted when a contract is published.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| operator `indexed` | address | undefined |
| publisher `indexed` | address | undefined |
| contractId `indexed` | uint256 | undefined |
| publishedContract  | IByocRegistry.CustomContract | undefined |

### ContractUnpublished

```solidity
event ContractUnpublished(address indexed operator, address indexed publisher, uint256 indexed contractId)
```



*Emitted when a contract is unpublished.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| operator `indexed` | address | undefined |
| publisher `indexed` | address | undefined |
| contractId `indexed` | uint256 | undefined |

### Paused

```solidity
event Paused(bool isPaused)
```



*Emitted when the registry is paused.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| isPaused  | bool | undefined |



