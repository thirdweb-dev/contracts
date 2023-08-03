# IAccountCore









## Methods

### factory

```solidity
function factory() external view returns (address)
```



*Returns the address of the factory from which the account was created.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getAllActiveSigners

```solidity
function getAllActiveSigners() external view returns (struct IAccountPermissions.SignerPermissions[] signers)
```

Returns all signers with active permissions to use the account.




#### Returns

| Name | Type | Description |
|---|---|---|
| signers | IAccountPermissions.SignerPermissions[] | undefined |

### getAllAdmins

```solidity
function getAllAdmins() external view returns (address[] admins)
```

Returns all admins of the account.




#### Returns

| Name | Type | Description |
|---|---|---|
| admins | address[] | undefined |

### getAllSigners

```solidity
function getAllSigners() external view returns (struct IAccountPermissions.SignerPermissions[] signers)
```

Returns all active and inactive signers of the account.




#### Returns

| Name | Type | Description |
|---|---|---|
| signers | IAccountPermissions.SignerPermissions[] | undefined |

### getPermissionsForSigner

```solidity
function getPermissionsForSigner(address signer) external view returns (struct IAccountPermissions.SignerPermissions permissions)
```

Returns the restrictions under which a signer can use the smart wallet.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| permissions | IAccountPermissions.SignerPermissions | undefined |

### isActiveSigner

```solidity
function isActiveSigner(address signer) external view returns (bool)
```

Returns whether the given account is an active signer on the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isAdmin

```solidity
function isAdmin(address signer) external view returns (bool)
```

Returns whether the given account is an admin.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |

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

### setAdmin

```solidity
function setAdmin(address account, bool isAdmin) external nonpayable
```

Adds / removes an account as an admin.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| isAdmin | bool | undefined |

### setPermissionsForSigner

```solidity
function setPermissionsForSigner(IAccountPermissions.SignerPermissionRequest req, bytes signature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| req | IAccountPermissions.SignerPermissionRequest | undefined |
| signature | bytes | undefined |

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

### verifySignerPermissionRequest

```solidity
function verifySignerPermissionRequest(IAccountPermissions.SignerPermissionRequest req, bytes signature) external view returns (bool success, address signer)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| req | IAccountPermissions.SignerPermissionRequest | undefined |
| signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined |
| signer | address | undefined |



## Events

### AdminUpdated

```solidity
event AdminUpdated(address indexed signer, bool isAdmin)
```

Emitted when an admin is set or removed.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer `indexed` | address | undefined |
| isAdmin  | bool | undefined |

### SignerPermissionsUpdated

```solidity
event SignerPermissionsUpdated(address indexed authorizingSigner, address indexed targetSigner, IAccountPermissions.SignerPermissionRequest permissions)
```

Emitted when permissions for a signer are updated.



#### Parameters

| Name | Type | Description |
|---|---|---|
| authorizingSigner `indexed` | address | undefined |
| targetSigner `indexed` | address | undefined |
| permissions  | IAccountPermissions.SignerPermissionRequest | undefined |



