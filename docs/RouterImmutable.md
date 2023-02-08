# RouterImmutable

*thirdweb.com*







## Methods

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



