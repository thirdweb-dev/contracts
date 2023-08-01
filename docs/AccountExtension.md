# AccountExtension









## Methods

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

### setPermissionsForSigner

```solidity
function setPermissionsForSigner(IAccountPermissions.SignerPermissionRequest _req, bytes _signature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _req | IAccountPermissions.SignerPermissionRequest | undefined |
| _signature | bytes | undefined |

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

### ContractURIUpdated

```solidity
event ContractURIUpdated(string prevURI, string newURI)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prevURI  | string | undefined |
| newURI  | string | undefined |

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



