# AccountPermissions









## Methods

### changeRole

```solidity
function changeRole(IAccountPermissions.RoleRequest _req, bytes _signature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _req | IAccountPermissions.RoleRequest | undefined |
| _signature | bytes | undefined |

### getAllRoleMembers

```solidity
function getAllRoleMembers(bytes32 _role) external view returns (address[])
```

Returns all accounts that have a role.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _role | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address[] | undefined |

### getRoleRestrictions

```solidity
function getRoleRestrictions(bytes32 _role) external view returns (struct IAccountPermissions.RoleRestrictions)
```

Returns the role restrictions for a given role.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _role | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IAccountPermissions.RoleRestrictions | undefined |

### getRoleRestrictionsForAccount

```solidity
function getRoleRestrictionsForAccount(address _account) external view returns (struct IAccountPermissions.RoleRestrictions)
```

Returns the role held by a given account along with its restrictions.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IAccountPermissions.RoleRestrictions | undefined |

### isAdmin

```solidity
function isAdmin(address _account) external view returns (bool)
```

Returns whether the given account is an admin.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### setAdmin

```solidity
function setAdmin(address _account, bool _isAdmin) external nonpayable
```

Adds / removes an account as an admin.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _account | address | undefined |
| _isAdmin | bool | undefined |

### setRoleRestrictions

```solidity
function setRoleRestrictions(IAccountPermissions.RoleRestrictions _restrictions) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _restrictions | IAccountPermissions.RoleRestrictions | undefined |

### verifyRoleRequest

```solidity
function verifyRoleRequest(IAccountPermissions.RoleRequest req, bytes signature) external view returns (bool success, address signer)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| req | IAccountPermissions.RoleRequest | undefined |
| signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined |
| signer | address | undefined |



## Events

### AdminUpdated

```solidity
event AdminUpdated(address indexed account, bool isAdmin)
```

Emitted when an admin is set or removed.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| isAdmin  | bool | undefined |

### RoleAssignment

```solidity
event RoleAssignment(bytes32 indexed role, address indexed account, address indexed signer, IAccountPermissions.RoleRequest request)
```

Emitted when a role is granted / revoked by an authorized party.



#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| account `indexed` | address | undefined |
| signer `indexed` | address | undefined |
| request  | IAccountPermissions.RoleRequest | undefined |

### RoleUpdated

```solidity
event RoleUpdated(bytes32 indexed role, IAccountPermissions.RoleRestrictions restrictions)
```

Emitted when the restrictions for a given role are updated.



#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| restrictions  | IAccountPermissions.RoleRestrictions | undefined |



