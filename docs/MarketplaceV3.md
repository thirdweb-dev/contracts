# MarketplaceV3

*thirdweb.com*







## Methods

### addPlugin

```solidity
function addPlugin(string _pluginName) external nonpayable
```



*Adds a new plugin to the router.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _pluginName | string | undefined |

### contractType

```solidity
function contractType() external pure returns (bytes32)
```



*Returns the type of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### contractVersion

```solidity
function contractVersion() external pure returns (uint8)
```



*Returns the version of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint8 | undefined |

### defaultPluginSet

```solidity
function defaultPluginSet() external view returns (address)
```

The DefaultPluginSet that stores default plugins of the router.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getAllFunctionsOfPlugin

```solidity
function getAllFunctionsOfPlugin(string _pluginName) external view returns (struct IPlugin.PluginFunction[])
```



*Returns all functions that belong to the given plugin contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _pluginName | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IPlugin.PluginFunction[] | undefined |

### getAllPlugins

```solidity
function getAllPlugins() external view returns (struct IPlugin.Plugin[] allPlugins)
```

Returns all plugins stored. Override default lugins stored in router are          given precedence over default plugins in DefaultPluginSet.




#### Returns

| Name | Type | Description |
|---|---|---|
| allPlugins | IPlugin.Plugin[] | undefined |

### getImplementationForFunction

```solidity
function getImplementationForFunction(bytes4 _functionSelector) external view returns (address pluginAddress)
```



*Returns the plugin implementation address stored in router, for the given function.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _functionSelector | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| pluginAddress | address | undefined |

### getPlugin

```solidity
function getPlugin(string _pluginName) external view returns (struct IPlugin.Plugin)
```



*Returns the plugin metadata and functions for a given plugin.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _pluginName | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IPlugin.Plugin | undefined |

### getPluginForFunction

```solidity
function getPluginForFunction(bytes4 _functionSelector) external view returns (struct IPlugin.PluginMetadata)
```



*Returns the plugin metadata for a given function.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _functionSelector | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IPlugin.PluginMetadata | undefined |

### getPluginImplementation

```solidity
function getPluginImplementation(string _pluginName) external view returns (address)
```



*Returns the plugin&#39;s implementation smart contract address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _pluginName | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### initialize

```solidity
function initialize(address _defaultAdmin, string _contractURI, address[] _trustedForwarders, address _platformFeeRecipient, uint16 _platformFeeBps) external nonpayable
```



*Initiliazes the contract, like a constructor.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _defaultAdmin | address | undefined |
| _contractURI | string | undefined |
| _trustedForwarders | address[] | undefined |
| _platformFeeRecipient | address | undefined |
| _platformFeeBps | uint16 | undefined |

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
function onERC721Received(address, address, uint256, bytes) external pure returns (bytes4)
```





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

### pluginRegistry

```solidity
function pluginRegistry() external view returns (address)
```

The PluginRegistry that stores all latest, vetted plugins available to router.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### removePlugin

```solidity
function removePlugin(string _pluginName) external nonpayable
```



*Removes an existing plugin from the router.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _pluginName | string | undefined |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```





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
function updatePlugin(string _pluginName) external nonpayable
```



*Updates an existing plugin in the router, or overrides a default plugin.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _pluginName | string | undefined |



## Events

### ContractURIUpdated

```solidity
event ContractURIUpdated(string prevURI, string newURI)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prevURI  | string | undefined |
| newURI  | string | undefined |

### Initialized

```solidity
event Initialized(uint8 version)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### PlatformFeeInfoUpdated

```solidity
event PlatformFeeInfoUpdated(address indexed platformFeeRecipient, uint256 platformFeeBps)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| platformFeeRecipient `indexed` | address | undefined |
| platformFeeBps  | uint256 | undefined |

### PluginAdded

```solidity
event PluginAdded(address indexed pluginAddress, bytes4 indexed functionSelector, string functionSignature)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| pluginAddress `indexed` | address | undefined |
| functionSelector `indexed` | bytes4 | undefined |
| functionSignature  | string | undefined |

### PluginRemoved

```solidity
event PluginRemoved(address indexed pluginAddress, bytes4 indexed functionSelector, string functionSignature)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| pluginAddress `indexed` | address | undefined |
| functionSelector `indexed` | bytes4 | undefined |
| functionSignature  | string | undefined |

### PluginUpdated

```solidity
event PluginUpdated(address indexed oldPluginAddress, address indexed newPluginAddress, bytes4 indexed functionSelector, string functionSignature)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| oldPluginAddress `indexed` | address | undefined |
| newPluginAddress `indexed` | address | undefined |
| functionSelector `indexed` | bytes4 | undefined |
| functionSignature  | string | undefined |

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



