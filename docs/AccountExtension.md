# AccountExtension









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

### contractURI

```solidity
function contractURI() external view returns (string)
```

Returns the contract metadata URI.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### execute

```solidity
function execute(address _target, uint256 _value, bytes _calldata) external nonpayable
```

Executes a transaction (called directly from an admin, or by entryPoint)



#### Parameters

| Name | Type | Description |
|---|---|---|
| _target | address | undefined |
| _value | uint256 | undefined |
| _calldata | bytes | undefined |

### executeBatch

```solidity
function executeBatch(address[] _target, uint256[] _value, bytes[] _calldata) external nonpayable
```

Executes a sequence transaction (called directly from an admin, or by entryPoint)



#### Parameters

| Name | Type | Description |
|---|---|---|
| _target | address[] | undefined |
| _value | uint256[] | undefined |
| _calldata | bytes[] | undefined |

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

### onERC1155BatchReceived

```solidity
function onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) external nonpayable returns (bytes4)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256[] | undefined |
| _3 | uint256[] | undefined |
| _4 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### onERC1155Received

```solidity
function onERC1155Received(address, address, uint256, uint256, bytes) external nonpayable returns (bytes4)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256 | undefined |
| _3 | uint256 | undefined |
| _4 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) external nonpayable returns (bytes4)
```



*See {IERC721Receiver-onERC721Received}. Always returns `IERC721Receiver.onERC721Received.selector`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256 | undefined |
| _3 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

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

### setContractURI

```solidity
function setContractURI(string _uri) external nonpayable
```

Lets a contract admin set the URI for contract-level metadata.

*Caller should be authorized to setup contractURI, e.g. contract admin.                  See {_canSetContractURI}.                  Emits {ContractURIUpdated Event}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _uri | string | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |

### setRoleRestrictions

```solidity
function setRoleRestrictions(IAccountPermissions.RoleRestrictions _restrictions) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _restrictions | IAccountPermissions.RoleRestrictions | undefined |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```

See {IERC165-supportsInterface}.



#### Parameters

| Name | Type | Description |
|---|---|---|
| interfaceId | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

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

### ContractURIUpdated

```solidity
event ContractURIUpdated(string prevURI, string newURI)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prevURI  | string | undefined |
| newURI  | string | undefined |

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



