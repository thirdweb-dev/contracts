# IRouter









## Methods

### addPlugin

```solidity
function addPlugin(IMap.Plugin _plugin) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _plugin | IMap.Plugin | undefined |

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
function getAllPlugins() external view returns (struct IMap.Plugin[])
```



*Returns all plug-ins known by Map.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IMap.Plugin[] | undefined |

### getPluginForFunction

```solidity
function getPluginForFunction(bytes4 selector) external view returns (address)
```



*Returns the plug-in contract for a given function.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| selector | bytes4 | undefined |

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

### updatePlugin

```solidity
function updatePlugin(IMap.Plugin _plugin) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _plugin | IMap.Plugin | undefined |



## Events

### PluginAdded

```solidity
event PluginAdded(bytes4 indexed selector, address indexed pluginAddress)
```



*Emitted when a functionality is added, or plugged-in.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| selector `indexed` | bytes4 | undefined |
| pluginAddress `indexed` | address | undefined |

### PluginRemoved

```solidity
event PluginRemoved(bytes4 indexed selector, address indexed pluginAddress)
```



*Emitted when a functionality is removed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| selector `indexed` | bytes4 | undefined |
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
event PluginUpdated(bytes4 indexed selector, address indexed oldPluginAddress, address indexed newPluginAddress)
```



*Emitted when a functionality is updated or overridden.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| selector `indexed` | bytes4 | undefined |
| oldPluginAddress `indexed` | address | undefined |
| newPluginAddress `indexed` | address | undefined |



