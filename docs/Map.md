# Map





TODO:      - Remove OZ EnumerableSet external dependency.



## Methods

### getAllFunctionsOfExtension

```solidity
function getAllFunctionsOfExtension(address _extension) external view returns (bytes4[] registered)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _extension | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| registered | bytes4[] | undefined |

### getAllRegistered

```solidity
function getAllRegistered() external view returns (struct IMap.ExtensionMap[] functionExtensionPairs)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| functionExtensionPairs | IMap.ExtensionMap[] | undefined |

### getExtensionForFunction

```solidity
function getExtensionForFunction(bytes4 _selector) external view returns (address)
```





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



## Events

### ExtensionRegistered

```solidity
event ExtensionRegistered(bytes4 indexed selector, address indexed extension)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| selector `indexed` | bytes4 | undefined |
| extension `indexed` | address | undefined |



