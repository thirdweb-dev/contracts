# EntrypointOverrideable









## Methods

### functionMap

```solidity
function functionMap() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getAllOverriden

```solidity
function getAllOverriden() external view returns (struct IEntrypointOverrideable.ExtensionMap[] functionExtensionPairs)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| functionExtensionPairs | IEntrypointOverrideable.ExtensionMap[] | undefined |

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

### overrideExtensionForFunction

```solidity
function overrideExtensionForFunction(bytes4 _selector, address _extension) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _selector | bytes4 | undefined |
| _extension | address | undefined |




