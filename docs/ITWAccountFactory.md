# ITWAccountFactory









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
function createAccount(bytes32 _salt, bytes _initData) external nonpayable returns (address account)
```

Deploys a new Account with the given salt and initialization data.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _salt | bytes32 | undefined |
| _initData | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

### getAddress

```solidity
function getAddress(bytes32 _salt) external view returns (address)
```

Returns the address of an Account that would be deployed with the given salt.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _salt | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |



## Events

### AccountCreated

```solidity
event AccountCreated(address indexed account, bytes32 salt)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| salt  | bytes32 | undefined |



