# TWFactory









## Methods

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined

### FACTORY_ROLE

```solidity
function FACTORY_ROLE() external view returns (bytes32)
```



*Only FACTORY_ROLE holders can approve/unapprove implementations for proxies to point to.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined

### addImplementation

```solidity
function addImplementation(address _implementation) external nonpayable
```



*Lets a contract admin set the address of a module type x version.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _implementation | address | undefined

### approval

```solidity
function approval(address) external view returns (bool)
```



*mapping of implementation address to deployment approval*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### approveImplementation

```solidity
function approveImplementation(address _implementation, bool _toApprove) external nonpayable
```



*Lets a contract admin approve a specific contract for deployment.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _implementation | address | undefined
| _toApprove | bool | undefined

### currentVersion

```solidity
function currentVersion(bytes32) external view returns (uint256)
```



*mapping of implementation address to implementation added version*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### deployProxy

```solidity
function deployProxy(bytes32 _type, bytes _data) external nonpayable returns (address)
```



*Deploys a proxy that points to the latest version of the given module type.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _type | bytes32 | undefined
| _data | bytes | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

### deployProxyByImplementation

```solidity
function deployProxyByImplementation(address _implementation, bytes _data, bytes32 _salt) external nonpayable returns (address deployedProxy)
```



*Deploys a proxy that points to the given implementation.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _implementation | address | undefined
| _data | bytes | undefined
| _salt | bytes32 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| deployedProxy | address | undefined

### deployProxyDeterministic

```solidity
function deployProxyDeterministic(bytes32 _type, bytes _data, bytes32 _salt) external nonpayable returns (address)
```



*Deploys a proxy at a deterministic address by taking in `salt` as a parameter.       Proxy points to the latest version of the given module type.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _type | bytes32 | undefined
| _data | bytes | undefined
| _salt | bytes32 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

### deployer

```solidity
function deployer(address) external view returns (address)
```



*mapping of proxy address to deployer address*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

### getImplementation

```solidity
function getImplementation(bytes32 _type, uint256 _version) external view returns (address)
```



*Returns the implementation given a module type and version.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _type | bytes32 | undefined
| _version | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

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

### implementation

```solidity
function implementation(bytes32, uint256) external view returns (address)
```



*mapping of contract type to module version to implementation address*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined
| _1 | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

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

### registry

```solidity
function registry() external view returns (contract TWRegistry)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract TWRegistry | undefined

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



## Events

### ImplementationAdded

```solidity
event ImplementationAdded(address implementation, bytes32 indexed contractType, uint256 version)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| implementation  | address | undefined |
| contractType `indexed` | bytes32 | undefined |
| version  | uint256 | undefined |

### ImplementationApproved

```solidity
event ImplementationApproved(address implementation, bool isApproved)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| implementation  | address | undefined |
| isApproved  | bool | undefined |

### ProxyDeployed

```solidity
event ProxyDeployed(address indexed implementation, address proxy, address indexed deployer)
```



*Emitted when a proxy is deployed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| implementation `indexed` | address | undefined |
| proxy  | address | undefined |
| deployer `indexed` | address | undefined |

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



