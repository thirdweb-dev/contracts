# BaseAccount





Basic account implementation. this contract provides the basic logic for implementing the IAccount interface  - validateUserOp specific account implementation should inherit it and provide the account-specific logic



## Methods

### entryPoint

```solidity
function entryPoint() external view returns (contract IEntryPoint)
```

return the entryPoint used by this account. subclass should return the current entryPoint used by this account.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IEntryPoint | undefined |

### nonce

```solidity
function nonce() external view returns (uint256)
```

return the account nonce. subclass should return a nonce value that is used both by _validateAndUpdateNonce, and by the external provider (to read the current nonce)




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### validateUserOp

```solidity
function validateUserOp(UserOperation userOp, bytes32 userOpHash, uint256 missingAccountFunds) external nonpayable returns (uint256 validationData)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userOp | UserOperation | undefined |
| userOpHash | bytes32 | undefined |
| missingAccountFunds | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| validationData | uint256 | undefined |




