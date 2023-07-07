# IAggregator





Aggregated Signatures validator.



## Methods

### aggregateSignatures

```solidity
function aggregateSignatures(UserOperation[] userOps) external view returns (bytes aggregatedSignature)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userOps | UserOperation[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| aggregatedSignature | bytes | undefined |

### validateSignatures

```solidity
function validateSignatures(UserOperation[] userOps, bytes signature) external view
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userOps | UserOperation[] | undefined |
| signature | bytes | undefined |

### validateUserOpSignature

```solidity
function validateUserOpSignature(UserOperation userOp) external view returns (bytes sigForUserOp)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userOp | UserOperation | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| sigForUserOp | bytes | undefined |




