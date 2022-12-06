# IAccountAdmin









## Methods

### changeSignerForAccount

```solidity
function changeSignerForAccount(IAccountAdmin.SignerUpdateParams params, bytes signature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| params | IAccountAdmin.SignerUpdateParams | undefined |
| signature | bytes | undefined |

### createAccount

```solidity
function createAccount(IAccountAdmin.CreateAccountParams params, bytes signature) external payable returns (address account)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| params | IAccountAdmin.CreateAccountParams | undefined |
| signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

### execute

```solidity
function execute(IAccountAdmin.TransactionRequest req, bytes signature) external payable returns (bool success, bytes result)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| req | IAccountAdmin.TransactionRequest | undefined |
| signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined |
| result | bytes | undefined |



## Events

### AccountCreated

```solidity
event AccountCreated(address indexed account, address indexed signerOfAccount, address indexed creator)
```

Emitted when an account is created.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| signerOfAccount `indexed` | address | undefined |
| creator `indexed` | address | undefined |

### CallResult

```solidity
event CallResult(bool success, bytes result)
```

Emitted on a call to an account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| success  | bool | undefined |
| result  | bytes | undefined |

### SignerUpdated

```solidity
event SignerUpdated(address indexed account, address indexed newSigner)
```

Emitted when the signer for an account is updated.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| newSigner `indexed` | address | undefined |



