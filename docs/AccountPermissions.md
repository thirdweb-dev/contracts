# AccountPermissions









## Methods

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
function getAllAdmins() external view returns (address[])
```

Returns all admins of the account.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address[] | undefined |

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
function getPermissionsForSigner(address signer) external view returns (struct IAccountPermissions.SignerPermissions)
```

Returns the restrictions under which a signer can use the smart wallet.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IAccountPermissions.SignerPermissions | undefined |

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

### setPermissionsForSigner

```solidity
function setPermissionsForSigner(IAccountPermissions.SignerPermissionRequest _req, bytes _signature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _req | IAccountPermissions.SignerPermissionRequest | undefined |
| _signature | bytes | undefined |

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



