# IEntrypointOverrideable









## Methods

### getAllOverriden

```solidity
function getAllOverriden() external view returns (struct IEntrypointOverrideable.ExtensionMap[] functionExtensionPairs)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| functionExtensionPairs | IEntrypointOverrideable.ExtensionMap[] | undefined |

### getFunctionMap

```solidity
function getFunctionMap() external view returns (address map)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| map | address | undefined |

### overrideExtensionForFunction

```solidity
function overrideExtensionForFunction(bytes4 _selector, address _extension) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _selector | bytes4 | undefined |
| _extension | address | undefined |




