# ManagedAccountFactory









## Methods

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### accountImplementation

```solidity
function accountImplementation() external view returns (address)
```

Returns the address of the Account implementation.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### addExtension

```solidity
function addExtension(IExtension.Extension _extension) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _extension | IExtension.Extension | undefined |

### createAccount

```solidity
function createAccount(address _admin, bytes _data) external nonpayable returns (address)
```

Deploys a new Account for admin.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _admin | address | undefined |
| _data | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### defaultExtension

```solidity
function defaultExtension() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getAccountsOfSigner

```solidity
function getAccountsOfSigner(address signer) external view returns (address[] accounts)
```

Returns all accounts that the given address is a signer of.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| accounts | address[] | undefined |

### getAddress

```solidity
function getAddress(address _adminSigner) external view returns (address)
```

Returns the address of an Account that would be deployed with the given admin signer.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _adminSigner | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getAllExtensions

```solidity
function getAllExtensions() external view returns (struct IExtension.Extension[] allExtensions)
```

Returns all extensions stored. Override default lugins stored in router are          given precedence over default extensions in DefaultExtensionSet.




#### Returns

| Name | Type | Description |
|---|---|---|
| allExtensions | IExtension.Extension[] | undefined |

### getAllFunctionsOfExtension

```solidity
function getAllFunctionsOfExtension(string _extensionName) external view returns (struct IExtension.ExtensionFunction[])
```



*Returns all functions that belong to the given extension contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _extensionName | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IExtension.ExtensionFunction[] | undefined |

### getExtension

```solidity
function getExtension(string _extensionName) external view returns (struct IExtension.Extension)
```



*Returns the extension metadata and functions for a given extension.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _extensionName | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IExtension.Extension | undefined |

### getExtensionForFunction

```solidity
function getExtensionForFunction(bytes4 _functionSelector) external view returns (struct IExtension.ExtensionMetadata)
```



*Returns the extension metadata for a given function.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _functionSelector | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IExtension.ExtensionMetadata | undefined |

### getExtensionImplementation

```solidity
function getExtensionImplementation(string _extensionName) external view returns (address)
```



*Returns the extension&#39;s implementation smart contract address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _extensionName | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getImplementationForFunction

```solidity
function getImplementationForFunction(bytes4 _functionSelector) external view returns (address)
```



*Returns the extension implementation address stored in router, for the given function.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _functionSelector | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getRoleAdmin

```solidity
function getRoleAdmin(bytes32 role) external view returns (bytes32)
```

Returns the admin role that controls the specified role.

*See {grantRole} and {revokeRole}.                  To change a role&#39;s admin, use {_setRoleAdmin}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### getRoleMember

```solidity
function getRoleMember(bytes32 role, uint256 index) external view returns (address member)
```

Returns the role-member from a list of members for a role,                  at a given index.

*Returns `member` who has `role`, at `index` of role-members list.                  See struct {RoleMembers}, and mapping {roleMembers}*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |
| index | uint256 | Index in list of current members for the role. |

#### Returns

| Name | Type | Description |
|---|---|---|
| member | address |  Address of account that has `role` |

### getRoleMemberCount

```solidity
function getRoleMemberCount(bytes32 role) external view returns (uint256 count)
```

Returns total number of accounts that have a role.

*Returns `count` of accounts that have `role`.                  See struct {RoleMembers}, and mapping {roleMembers}*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |

#### Returns

| Name | Type | Description |
|---|---|---|
| count | uint256 |   Total number of accounts that have `role` |

### getSignersOfAccount

```solidity
function getSignersOfAccount(address account) external view returns (address[] signers)
```

Returns all signers of an account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| signers | address[] | undefined |

### grantRole

```solidity
function grantRole(bytes32 role, address account) external nonpayable
```

Grants a role to an account, if not previously granted.

*Caller must have admin role for the `role`.                  Emits {RoleGranted Event}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |
| account | address | Address of the account to which the role is being granted. |

### hasRole

```solidity
function hasRole(bytes32 role, address account) external view returns (bool)
```

Checks whether an account has a particular role.

*Returns `true` if `account` has been granted `role`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |
| account | address | Address of the account for which the role is being checked. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### hasRoleWithSwitch

```solidity
function hasRoleWithSwitch(bytes32 role, address account) external view returns (bool)
```

Checks whether an account has a particular role;                  role restrictions can be swtiched on and off.

*Returns `true` if `account` has been granted `role`.                  Role restrictions can be swtiched on and off:                      - If address(0) has ROLE, then the ROLE restrictions                        don&#39;t apply.                      - If address(0) does not have ROLE, then the ROLE                        restrictions will apply.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |
| account | address | Address of the account for which the role is being checked. |

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

### onSignerAdded

```solidity
function onSignerAdded(address _signer) external nonpayable
```

Callback function for an Account to register its signers.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |

### onSignerRemoved

```solidity
function onSignerRemoved(address _signer) external nonpayable
```

Callback function for an Account to un-register its signers.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |

### removeExtension

```solidity
function removeExtension(string _extensionName) external nonpayable
```



*Removes an existing extension from the router.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _extensionName | string | undefined |

### renounceRole

```solidity
function renounceRole(bytes32 role, address account) external nonpayable
```

Revokes role from the account.

*Caller must have the `role`, with caller being the same as `account`.                  Emits {RoleRevoked Event}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |
| account | address | Address of the account from which the role is being revoked. |

### revokeRole

```solidity
function revokeRole(bytes32 role, address account) external nonpayable
```

Revokes role from an account.

*Caller must have admin role for the `role`.                  Emits {RoleRevoked Event}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |
| account | address | Address of the account from which the role is being revoked. |

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

### updateExtension

```solidity
function updateExtension(IExtension.Extension _extension) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _extension | IExtension.Extension | undefined |



## Events

### AccountCreated

```solidity
event AccountCreated(address indexed account, address indexed accountAdmin)
```

Emitted when a new Account is created.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| accountAdmin `indexed` | address | undefined |

### ExtensionAdded

```solidity
event ExtensionAdded(address indexed extensionAddress, bytes4 indexed functionSelector, string functionSignature)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| extensionAddress `indexed` | address | undefined |
| functionSelector `indexed` | bytes4 | undefined |
| functionSignature  | string | undefined |

### ExtensionRemoved

```solidity
event ExtensionRemoved(address indexed extensionAddress, bytes4 indexed functionSelector, string functionSignature)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| extensionAddress `indexed` | address | undefined |
| functionSelector `indexed` | bytes4 | undefined |
| functionSignature  | string | undefined |

### ExtensionUpdated

```solidity
event ExtensionUpdated(address indexed oldExtensionAddress, address indexed newExtensionAddress, bytes4 indexed functionSelector, string functionSignature)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| oldExtensionAddress `indexed` | address | undefined |
| newExtensionAddress `indexed` | address | undefined |
| functionSelector `indexed` | bytes4 | undefined |
| functionSignature  | string | undefined |

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

### SignerAdded

```solidity
event SignerAdded(address indexed account, address indexed signer)
```

Emitted when a new signer is added to an Account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| signer `indexed` | address | undefined |

### SignerRemoved

```solidity
event SignerRemoved(address indexed account, address indexed signer)
```

Emitted when a new signer is added to an Account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| signer `indexed` | address | undefined |



