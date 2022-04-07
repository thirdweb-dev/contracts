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

### deployInstance

```solidity
function deployInstance(address publisher, uint256 contractId, bytes contractBytecode, bytes constructorArgs, bytes32 salt, uint256 value) external nonpayable returns (address deployedAddress)
```

Deploys an instance of a published contract directly.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher. 
| contractId | uint256 | The unique integer identifier of the published contract. (publisher address, contractId) =&gt; published contract.
| contractBytecode | bytes | The bytecode of the contract to deploy.
| constructorArgs | bytes | The encoded constructor args to deploy the contract with.
| salt | bytes32 | The salt to use in the CREATE2 contract deployment.
| value | uint256 | The native token value to pass to the contract on deployment.

#### Returns

| Name | Type | Description |
|---|---|---|
| deployedAddress | address | The address of the contract deployed.

### deployInstanceProxy

```solidity
function deployInstanceProxy(address publisher, uint256 contractId, bytes initializeData, bytes32 salt, uint256 value) external nonpayable returns (address deployedAddress)
```

Deploys a clone pointing to an implementation of a published contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher. 
| contractId | uint256 | The unique integer identifier of the published contract. (publisher address, contractId) =&gt; published contract.
| initializeData | bytes | The encoded function call to initialize the contract with.
| salt | bytes32 | The salt to use in the CREATE2 contract deployment.
| value | uint256 | The native token value to pass to the contract on deployment.

#### Returns

| Name | Type | Description |
|---|---|---|
| deployedAddress | address | The address of the contract deployed.

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
function publishContract(address publisher, string publishMetadataUri, bytes32 bytecodeHash, address implementation) external nonpayable returns (uint256 contractId)
```

Let&#39;s an account publish a contract. The account must be approved by the publisher, or be the publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | The address of the publisher.
| publishMetadataUri | string | The IPFS URI of the publish metadata.
| bytecodeHash | bytes32 | The keccak256 hash of the contract bytecode.
| implementation | address | (Optional) An implementation address that proxy contracts / clones can point to. Default value                        if such an implementation does not exist - address(0);

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

### ContractDeployed

```solidity
event ContractDeployed(address indexed deployer, address indexed publisher, uint256 indexed contractId, address deployedContract)
```



*Emitted when a contract is deployed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| deployer `indexed` | address | undefined |
| publisher `indexed` | address | undefined |
| contractId `indexed` | uint256 | undefined |
| deployedContract  | address | undefined |

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



