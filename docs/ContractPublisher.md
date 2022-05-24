# ContractPublisher









## Methods

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined

### addToPublicList

```solidity
function addToPublicList(address _publisher, string _contractId) external nonpayable
```

Lets an account add a published contract (and all its versions). The account must be approved by the publisher, or be the publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _publisher | address | undefined
| _contractId | string | undefined

### approveOperator

```solidity
function approveOperator(address _operator, bool _toApprove) external nonpayable
```

Lets a publisher (caller) approve an operator to publish / unpublish contracts on their behalf.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _operator | address | undefined
| _toApprove | bool | undefined

### getAllPublicPublishedContracts

```solidity
function getAllPublicPublishedContracts() external view returns (struct IContractPublisher.CustomContractInstance[] published)
```

Returns the latest version of all contracts published by a publisher.




#### Returns

| Name | Type | Description |
|---|---|---|
| published | IContractPublisher.CustomContractInstance[] | undefined

### getAllPublishedContracts

```solidity
function getAllPublishedContracts(address _publisher) external view returns (struct IContractPublisher.CustomContractInstance[] published)
```

Returns the latest version of all contracts published by a publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _publisher | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IContractPublisher.CustomContractInstance[] | undefined

### getPublicId

```solidity
function getPublicId(address _publisher, string _contractId) external view returns (uint256 publicId)
```

Returns the public id of a published contract, if it is public.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _publisher | address | undefined
| _contractId | string | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| publicId | uint256 | undefined

### getPublishedContract

```solidity
function getPublishedContract(address _publisher, string _contractId) external view returns (struct IContractPublisher.CustomContractInstance published)
```

Returns the latest version of a contract published by a publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _publisher | address | undefined
| _contractId | string | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IContractPublisher.CustomContractInstance | undefined

### getPublishedContractVersions

```solidity
function getPublishedContractVersions(address _publisher, string _contractId) external view returns (struct IContractPublisher.CustomContractInstance[] published)
```

Returns all versions of a published contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _publisher | address | undefined
| _contractId | string | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IContractPublisher.CustomContractInstance[] | undefined

### getRoleAdmin

```solidity
function getRoleAdmin(bytes32 role) external view returns (bytes32)
```



*Returns the admin role that controls `role`. See {grantRole} and {revokeRole}. To change a role&#39;s admin, use {_setRoleAdmin}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined

### getRoleMember

```solidity
function getRoleMember(bytes32 role, uint256 index) external view returns (address)
```



*Returns one of the accounts that have `role`. `index` must be a value between 0 and {getRoleMemberCount}, non-inclusive. Role bearers are not sorted in any particular way, and their ordering may change at any point. WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure you perform all queries on the same block. See the following https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post] for more information.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined
| index | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

### getRoleMemberCount

```solidity
function getRoleMemberCount(bytes32 role) external view returns (uint256)
```



*Returns the number of accounts that have `role`. Can be used together with {getRoleMember} to enumerate all bearers of a role.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### grantRole

```solidity
function grantRole(bytes32 role, address account) external nonpayable
```



*Grants `role` to `account`. If `account` had not been already granted `role`, emits a {RoleGranted} event. Requirements: - the caller must have ``role``&#39;s admin role.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined
| account | address | undefined

### hasRole

```solidity
function hasRole(bytes32 role, address account) external view returns (bool)
```



*Returns `true` if `account` has been granted `role`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined
| account | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### isApprovedByPublisher

```solidity
function isApprovedByPublisher(address, address) external view returns (bool)
```



*Mapping from publisher address =&gt; operator address =&gt; whether publisher has approved operator       to publish / unpublish contracts on their behalf.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined
| _1 | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### isPaused

```solidity
function isPaused() external view returns (bool)
```



*Whether the registry is paused.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### isTrustedForwarder

```solidity
function isTrustedForwarder(address forwarder) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| forwarder | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### multicall

```solidity
function multicall(bytes[] data) external nonpayable returns (bytes[] results)
```



*Receives and executes a batch of function calls on this contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes[] | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| results | bytes[] | undefined

### nextPublicId

```solidity
function nextPublicId() external view returns (uint256)
```



*The global Id for publicly published contracts.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### publishContract

```solidity
function publishContract(address _publisher, string _publishMetadataUri, bytes32 _bytecodeHash, address _implementation, string _contractId) external nonpayable
```

Let&#39;s an account publish a contract. The account must be approved by the publisher, or be the publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _publisher | address | undefined
| _publishMetadataUri | string | undefined
| _bytecodeHash | bytes32 | undefined
| _implementation | address | undefined
| _contractId | string | undefined

### removeFromPublicList

```solidity
function removeFromPublicList(address _publisher, string _contractId) external nonpayable
```

Lets an account remove a published contract (and all its versions). The account must be approved by the publisher, or be the publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _publisher | address | undefined
| _contractId | string | undefined

### renounceRole

```solidity
function renounceRole(bytes32 role, address account) external nonpayable
```



*Revokes `role` from the calling account. Roles are often managed via {grantRole} and {revokeRole}: this function&#39;s purpose is to provide a mechanism for accounts to lose their privileges if they are compromised (such as when a trusted device is misplaced). If the calling account had been revoked `role`, emits a {RoleRevoked} event. Requirements: - the caller must be `account`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined
| account | address | undefined

### revokeRole

```solidity
function revokeRole(bytes32 role, address account) external nonpayable
```



*Revokes `role` from `account`. If `account` had been granted `role`, emits a {RoleRevoked} event. Requirements: - the caller must have ``role``&#39;s admin role.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined
| account | address | undefined

### setPause

```solidity
function setPause(bool _pause) external nonpayable
```



*Lets a contract admin pause the registry.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _pause | bool | undefined

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```



*See {IERC165-supportsInterface}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| interfaceId | bytes4 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### unpublishContract

```solidity
function unpublishContract(address _publisher, string _contractId) external nonpayable
```

Lets an account unpublish a contract and all its versions. The account must be approved by the publisher, or be the publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _publisher | address | undefined
| _contractId | string | undefined



## Events

### AddedContractToPublicList

```solidity
event AddedContractToPublicList(address indexed publisher, string indexed contractId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher `indexed` | address | undefined |
| contractId `indexed` | string | undefined |

### Approved

```solidity
event Approved(address indexed publisher, address indexed operator, bool isApproved)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher `indexed` | address | undefined |
| operator `indexed` | address | undefined |
| isApproved  | bool | undefined |

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

### RemovedContractToPublicList

```solidity
event RemovedContractToPublicList(address indexed publisher, string indexed contractId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher `indexed` | address | undefined |
| contractId `indexed` | string | undefined |

### RoleAdminChanged

```solidity
event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| previousAdminRole `indexed` | bytes32 | undefined |
| newAdminRole `indexed` | bytes32 | undefined |

### RoleGranted

```solidity
event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| account `indexed` | address | undefined |
| sender `indexed` | address | undefined |

### RoleRevoked

```solidity
event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| account `indexed` | address | undefined |
| sender `indexed` | address | undefined |



