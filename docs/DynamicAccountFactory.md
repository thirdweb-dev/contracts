# DynamicAccountFactory









## Methods

### accountImplementation

```solidity
function accountImplementation() external view returns (address)
```

Returns the implementation of the Account.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### createAccount

```solidity
function createAccount(address _admin, string _accountId) external nonpayable returns (address)
```

Deploys a new Account with the given admin and accountId used as salt.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _admin | address | undefined |
| _accountId | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getAddress

```solidity
function getAddress(string _accountId) external view returns (address)
```

Returns the address of an Account that would be deployed with the given accountId as salt.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _accountId | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

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



## Events

### AccountCreated

```solidity
event AccountCreated(address indexed account, address indexed accountAdmin, string accountId)
```

Emitted when a new Account is created.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| accountAdmin `indexed` | address | undefined |
| accountId  | string | undefined |



