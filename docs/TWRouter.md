# TWRouter









## Methods

### addExtension

```solidity
function addExtension(string _extensionName) external nonpayable
```



*Adds a new extension to the router.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _extensionName | string | undefined |

### defaultExtensionSet

```solidity
function defaultExtensionSet() external view returns (address)
```

The DefaultExtensionSet that stores default extensions of the router.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### extensionRegistry

```solidity
function extensionRegistry() external view returns (address)
```

The ExtensionRegistry that stores all latest, vetted extensions available to router.




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



*Returns the Extension metadata for a given function.*

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
function getImplementationForFunction(bytes4 _functionSelector) external view returns (address extensionAddress)
```



*Returns the extension implementation address stored in router, for the given function.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _functionSelector | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| extensionAddress | address | undefined |

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

### removeExtension

```solidity
function removeExtension(string _extensionName) external nonpayable
```



*Removes an existing extension from the router.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _extensionName | string | undefined |

### updateExtension

```solidity
function updateExtension(string _extensionName) external nonpayable
```



*Updates an existing extension in the router, or overrides a default extension.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _extensionName | string | undefined |



## Events

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



