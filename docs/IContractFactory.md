# IContractFactory

*thirdweb*







## Methods

### deployProxyByImplementation

```solidity
function deployProxyByImplementation(address implementation, bytes data, bytes32 salt) external nonpayable returns (address)
```

Deploys a proxy that points to that points to the given implementation.



#### Parameters

| Name | Type | Description |
|---|---|---|
| implementation | address | Address of the implementation to point to. |
| data | bytes | Additional data to pass to the proxy constructor or any other data useful during deployement. |
| salt | bytes32 | Salt to use for the deterministic address generation. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |




