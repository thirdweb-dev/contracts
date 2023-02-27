# TWStatelessFactory









## Methods

### deployProxyByImplementation

```solidity
function deployProxyByImplementation(address _implementation, bytes _data, bytes32 _salt) external nonpayable returns (address deployedProxy)
```



*Deploys a proxy that points to the given implementation.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _implementation | address | undefined |
| _data | bytes | undefined |
| _salt | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| deployedProxy | address | undefined |

### isTrustedForwarder

```solidity
function isTrustedForwarder(address forwarder) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| forwarder | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### multicall

```solidity
function multicall(bytes[] data) external nonpayable returns (bytes[] results)
```



*Receives and executes a batch of function calls on this contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| results | bytes[] | undefined |



## Events

### ProxyDeployed

```solidity
event ProxyDeployed(address indexed implementation, address proxy, address indexed deployer)
```



*Emitted when a proxy is deployed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| implementation `indexed` | address | undefined |
| proxy  | address | undefined |
| deployer `indexed` | address | undefined |



