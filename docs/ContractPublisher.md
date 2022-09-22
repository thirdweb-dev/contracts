# ContractPublisher









## Methods

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### getAllPublishedContracts

```solidity
function getAllPublishedContracts(address _publisher) external view returns (struct IContractPublisher.CustomContractInstance[] published)
```

Returns the latest version of all contracts published by a publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _publisher | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IContractPublisher.CustomContractInstance[] | undefined |

### getPublishedContract

```solidity
function getPublishedContract(address _publisher, string _contractId) external view returns (struct IContractPublisher.CustomContractInstance published)
```

Returns the latest version of a contract published by a publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _publisher | address | undefined |
| _contractId | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IContractPublisher.CustomContractInstance | undefined |

### getPublishedContractVersions

```solidity
function getPublishedContractVersions(address _publisher, string _contractId) external view returns (struct IContractPublisher.CustomContractInstance[] published)
```

Returns all versions of a published contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _publisher | address | undefined |
| _contractId | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IContractPublisher.CustomContractInstance[] | undefined |

### getPublishedUriFromCompilerUri

```solidity
function getPublishedUriFromCompilerUri(string compilerMetadataUri) external view returns (string[] publishedMetadataUris)
```

Retrieve the published metadata URI from a compiler metadata URI



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

### getRoleAdmin

```solidity
function getRoleAdmin(bytes32 role) external view returns (bytes32)
```



*Returns the admin role that controls `role`. See {grantRole} and {revokeRole}. To change a role&#39;s admin, use {_setRoleAdmin}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### getRoleMember

```solidity
function getRoleMember(bytes32 role, uint256 index) external view returns (address)
```



*Returns one of the accounts that have `role`. `index` must be a value between 0 and {getRoleMemberCount}, non-inclusive. Role bearers are not sorted in any particular way, and their ordering may change at any point. WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure you perform all queries on the same block. See the following https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post] for more information.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| index | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getRoleMemberCount

```solidity
function getRoleMemberCount(bytes32 role) external view returns (uint256)
```



*Returns the number of accounts that have `role`. Can be used together with {getRoleMember} to enumerate all bearers of a role.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### grantRole

```solidity
function grantRole(bytes32 role, address account) external nonpayable
```



*Grants `role` to `account`. If `account` had not been already granted `role`, emits a {RoleGranted} event. Requirements: - the caller must have ``role``&#39;s admin role. May emit a {RoleGranted} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

### hasRole

```solidity
function hasRole(bytes32 role, address account) external view returns (bool)
```



*Returns `true` if `account` has been granted `role`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isPaused

```solidity
function isPaused() external view returns (bool)
```

Whether the contract publisher is paused.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isTrustedForwarder

```solidity
function isTrustedForwarder(address forwarder) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| forwarder | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### multicall

```solidity
function multicall(bytes[] data) external nonpayable returns (bytes[] results)
```



*Receives and executes a batch of function calls on this contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| results | bytes[] | undefined |

### prevPublisher

```solidity
function prevPublisher() external view returns (contract IContractPublisher)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IContractPublisher | undefined |

### publishContract

```solidity
function publishContract(address _publisher, string _contractId, string _publishMetadataUri, string _compilerMetadataUri, bytes32 _bytecodeHash, address _implementation) external nonpayable
```

Let&#39;s an account publish a contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _publisher | address | undefined |
| _contractId | string | undefined |
| _publishMetadataUri | string | undefined |
| _compilerMetadataUri | string | undefined |
| _bytecodeHash | bytes32 | undefined |
| _implementation | address | undefined |

### renounceRole

```solidity
function renounceRole(bytes32 role, address account) external nonpayable
```



*Revokes `role` from the calling account. Roles are often managed via {grantRole} and {revokeRole}: this function&#39;s purpose is to provide a mechanism for accounts to lose their privileges if they are compromised (such as when a trusted device is misplaced). If the calling account had been revoked `role`, emits a {RoleRevoked} event. Requirements: - the caller must be `account`. May emit a {RoleRevoked} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

### revokeRole

```solidity
function revokeRole(bytes32 role, address account) external nonpayable
```



*Revokes `role` from `account`. If `account` had been granted `role`, emits a {RoleRevoked} event. Requirements: - the caller must have ``role``&#39;s admin role. May emit a {RoleRevoked} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

### setPause

```solidity
function setPause(bool _pause) external nonpayable
```



*Lets a contract admin pause the registry.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _pause | bool | undefined |

### setPublisherProfileUri

```solidity
function setPublisherProfileUri(address publisher, string uri) external nonpayable
```

Lets an account set its own publisher profile uri



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | undefined |
| uri | string | undefined |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```



*See {IERC165-supportsInterface}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| interfaceId | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### unpublishContract

```solidity
function unpublishContract(address _publisher, string _contractId) external nonpayable
```

Lets a publisher unpublish a contract and all its versions.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _publisher | address | undefined |
| _contractId | string | undefined |



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



