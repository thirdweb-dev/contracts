# IAccountFactory









## Methods

### accountImplementation

```solidity
function accountImplementation() external view returns (address)
```

Returns the address of the Account implementation.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### createAccount

```solidity
function createAccount(address admin, string accountId) external nonpayable returns (address account)
```

Deploys a new Account with the given admin and accountId used as salt.



#### Parameters

| Name | Type | Description |
|---|---|---|
| admin | address | undefined |
| accountId | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

### getAddress

```solidity
function getAddress(string accountId) external view returns (address)
```

Returns the address of an Account that would be deployed with the given accountId as salt.



#### Parameters

| Name | Type | Description |
|---|---|---|
| accountId | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |



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



