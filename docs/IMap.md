# IMap









## Methods

### getExtension

```solidity
function getExtension(bytes4 _selector) external view returns (address)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _selector | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### setExtension

```solidity
function setExtension(bytes4 _selector, address _extension) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _selector | bytes4 | undefined |
| _extension | address | undefined |



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



