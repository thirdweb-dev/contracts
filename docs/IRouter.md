# IRouter









## Methods

### addPlugin

```solidity
function addPlugin(IPluginMap.Plugin plugin) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| plugin | IPluginMap.Plugin | undefined |

### getAllFunctionsOfPlugin

```solidity
function getAllFunctionsOfPlugin(address pluginAddress) external view returns (bytes4[])
```



*Returns all functions that are mapped to the given plug-in contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| pluginAddress | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4[] | undefined |

### getAllPlugins

```solidity
function getAllPlugins() external view returns (struct IPluginMap.Plugin[])
```



*Returns all plug-ins known by Map.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IPluginMap.Plugin[] | undefined |

### getPluginForFunction

```solidity
function getPluginForFunction(bytes4 functionSelector) external view returns (address)
```



*Returns the plug-in contract for a given function.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| functionSelector | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### removePlugin

```solidity
function removePlugin(bytes4 functionSelector) external nonpayable
```



*Remove an existing plugin from the contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| functionSelector | bytes4 | undefined |

### updatePlugin

```solidity
function updatePlugin(IPluginMap.Plugin plugin) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| plugin | IPluginMap.Plugin | undefined |



## Events

### PluginAdded

```solidity
event PluginAdded(bytes4 indexed functionSelector, address indexed pluginAddress)
```



*Emitted when a functionality is added, or plugged-in.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| functionSelector `indexed` | bytes4 | undefined |
| pluginAddress `indexed` | address | undefined |

### PluginRemoved

```solidity
event PluginRemoved(bytes4 indexed functionSelector, address indexed pluginAddress)
```



*Emitted when a functionality is removed.*

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



*Emitted when a functionality is updated or overridden.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| functionSelector `indexed` | bytes4 | undefined |
| oldPluginAddress `indexed` | address | undefined |
| newPluginAddress `indexed` | address | undefined |



