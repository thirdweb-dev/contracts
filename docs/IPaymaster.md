# IPaymaster





the interface exposed by a paymaster contract, who agrees to pay the gas for user&#39;s operations. a paymaster must hold a stake to cover the required entrypoint stake and also the gas for the transaction.



## Methods

### postOp

```solidity
function postOp(enum IPaymaster.PostOpMode mode, bytes context, uint256 actualGasCost) external nonpayable
```

post-operation handler. Must verify sender is the entryPoint



#### Parameters

| Name | Type | Description |
|---|---|---|
| mode | enum IPaymaster.PostOpMode | enum with the following options:      opSucceeded - user operation succeeded.      opReverted  - user op reverted. still has to pay for gas.      postOpReverted - user op succeeded, but caused postOp (in mode=opSucceeded) to revert.                       Now this is the 2nd call, after user&#39;s op was deliberately reverted. |
| context | bytes | - the context value returned by validatePaymasterUserOp |
| actualGasCost | uint256 | - actual gas used so far (without this postOp call). |

### validatePaymasterUserOp

```solidity
function validatePaymasterUserOp(UserOperation userOp, bytes32 userOpHash, uint256 maxCost) external nonpayable returns (bytes context, uint256 validationData)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userOp | UserOperation | undefined |
| userOpHash | bytes32 | undefined |
| maxCost | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| context | bytes | undefined |
| validationData | uint256 | undefined |




