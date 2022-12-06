# AccountAdmin





Basic actions:      - Create accounts.      - Change signer of account.      - Relay transaction to contract wallet.



## Methods

### accountOf

```solidity
function accountOf(bytes32) external view returns (address)
```



*Mapping from hash(signer, credentials) =&gt; account.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### changeSignerForAccount

```solidity
function changeSignerForAccount(IAccountAdmin.SignerUpdateParams _params, bytes _signature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _params | IAccountAdmin.SignerUpdateParams | undefined |
| _signature | bytes | undefined |

### createAccount

```solidity
function createAccount(IAccountAdmin.CreateAccountParams _params, bytes _signature) external payable returns (address account)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _params | IAccountAdmin.CreateAccountParams | undefined |
| _signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

### credentialsOf

```solidity
function credentialsOf(address) external view returns (bytes32)
```



*Mapping from signer =&gt; credentials.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### execute

```solidity
function execute(IAccountAdmin.TransactionRequest req, bytes signature) external payable returns (bool, bytes)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| req | IAccountAdmin.TransactionRequest | undefined |
| signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |
| _1 | bytes | undefined |

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

### signerOf

```solidity
function signerOf(bytes32) external view returns (address)
```



*Mapping from credentials =&gt; signer.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |



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



