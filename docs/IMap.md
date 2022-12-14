# IMap









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
function getAllRegistered() external view returns (struct IMap.ExtensionMap[] registered)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| registered | IMap.ExtensionMap[] | undefined |

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



