# TWMultichainRegistryRouter





&quot;Inherited by entrypoint&quot; extensions.      - PermissionsEnumerable      - ERC2771Context      - Multicall      &quot;NOT inherited by entrypoint&quot; extensions.      - TWMultichainRegistry



## Methods

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### _getPluginForFunction

```solidity
function _getPluginForFunction(bytes4 _selector) external view returns (address)
```



*View address of the plugged-in functionality contract for a given function signature.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _selector | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### addPlugin

```solidity
function addPlugin(IPluginMap.Plugin _plugin) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _plugin | IPluginMap.Plugin | undefined |

### getAllFunctionsOfPlugin

```solidity
function getAllFunctionsOfPlugin(address _pluginAddress) external view returns (bytes4[] registered)
```



*View all funtionality as list of function signatures.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _pluginAddress | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| registered | bytes4[] | undefined |

### getAllPlugins

```solidity
function getAllPlugins() external view returns (struct IPluginMap.Plugin[] registered)
```



*View all funtionality existing on the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| registered | IPluginMap.Plugin[] | undefined |

### getPluginForFunction

```solidity
function getPluginForFunction(bytes4 _selector) external view returns (address)
```



*View address of the plugged-in functionality contract for a given function signature.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _selector | bytes4 | undefined |

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

### pluginMap

```solidity
function pluginMap() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### removePlugin

```solidity
function removePlugin(bytes4 _selector) external nonpayable
```



*Remove existing functionality from the contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _selector | bytes4 | undefined |

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

### updatePlugin

```solidity
function updatePlugin(IPluginMap.Plugin _plugin) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _plugin | IPluginMap.Plugin | undefined |



## Events

### PluginAdded

```solidity
event PluginAdded(bytes4 indexed functionSelector, address indexed pluginAddress)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| functionSelector `indexed` | bytes4 | undefined |
| pluginAddress `indexed` | address | undefined |

### PluginRemoved

```solidity
event PluginRemoved(bytes4 indexed functionSelector, address indexed pluginAddress)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| functionSelector `indexed` | bytes4 | undefined |
| pluginAddress `indexed` | address | undefined |

### PluginSet

```solidity
event PluginSet(bytes4 indexed functionSelector, string indexed functionSignature, address indexed pluginAddress)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| functionSelector `indexed` | bytes4 | undefined |
| functionSignature `indexed` | string | undefined |
| pluginAddress `indexed` | address | undefined |

### PluginUpdated

```solidity
event PluginUpdated(bytes4 indexed functionSelector, address indexed oldPluginAddress, address indexed newPluginAddress)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| functionSelector `indexed` | bytes4 | undefined |
| oldPluginAddress `indexed` | address | undefined |
| newPluginAddress `indexed` | address | undefined |

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



