# ManagedAccount









## Methods

### addDeposit

```solidity
function addDeposit() external payable
```

Deposit funds for this account in Entrypoint.




### changeRole

```solidity
function changeRole(IAccountPermissions.RoleRequest _req, bytes _signature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _req | IAccountPermissions.RoleRequest | undefined |
| _signature | bytes | undefined |

### entryPoint

```solidity
function entryPoint() external view returns (contract IEntryPoint)
```

Returns the EIP 4337 entrypoint contract.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IEntryPoint | undefined |

### factory

```solidity
function factory() external view returns (address)
```

EIP 4337 factory for this contract.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

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

### getDeposit

```solidity
function getDeposit() external view returns (uint256)
```

Returns the balance of the account in Entrypoint.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getImplementationForFunction

```solidity
function getImplementationForFunction(bytes4 _functionSelector) external view returns (address)
```

Returns the implementation contract address for a given function signature.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _functionSelector | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getNonce

```solidity
function getNonce() external view returns (uint256)
```

Return the account nonce. This method returns the next sequential nonce. For a nonce of a specific key, use `entrypoint.getNonce(account, key)`




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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

### initialize

```solidity
function initialize(address _defaultAdmin, bytes) external nonpayable
```

Initializes the smart contract wallet.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _defaultAdmin | address | undefined |
| _1 | bytes | undefined |

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

### isValidSignature

```solidity
function isValidSignature(bytes32 _hash, bytes _signature) external view returns (bytes4 magicValue)
```

See EIP-1271



#### Parameters

| Name | Type | Description |
|---|---|---|
| _hash | bytes32 | undefined |
| _signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| magicValue | bytes4 | undefined |

### isValidSigner

```solidity
function isValidSigner(address _signer, UserOperation _userOp) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |
| _userOp | UserOperation | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### multicall

```solidity
function multicall(bytes[] data) external nonpayable returns (bytes[] results)
```

Receives and executes a batch of function calls on this contract.

*Receives and executes a batch of function calls on this contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes[] | The bytes data that makes up the batch of function calls to execute. |

#### Returns

| Name | Type | Description |
|---|---|---|
| results | bytes[] | The bytes data that makes up the result of the batch of function calls executed. |

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

### validateUserOp

```solidity
function validateUserOp(UserOperation userOp, bytes32 userOpHash, uint256 missingAccountFunds) external nonpayable returns (uint256 validationData)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userOp | UserOperation | undefined |
| userOpHash | bytes32 | undefined |
| missingAccountFunds | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| validationData | uint256 | undefined |

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

### withdrawDepositTo

```solidity
function withdrawDepositTo(address payable withdrawAddress, uint256 amount) external nonpayable
```

Withdraw funds for this account from Entrypoint.



#### Parameters

| Name | Type | Description |
|---|---|---|
| withdrawAddress | address payable | undefined |
| amount | uint256 | undefined |



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

### Initialized

```solidity
event Initialized(uint8 version)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

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



