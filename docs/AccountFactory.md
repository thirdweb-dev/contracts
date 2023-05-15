# AccountFactory









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
function createAccount(address _admin, bytes _data) external nonpayable returns (address)
```

Deploys a new Account for admin.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _admin | address | undefined |
| _data | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getAccountsOfSigner

```solidity
function getAccountsOfSigner(address signer) external view returns (address[] accounts)
```

Returns all accounts that the given address is a signer of.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| accounts | address[] | undefined |

### getAddress

```solidity
function getAddress(address _adminSigner) external view returns (address)
```

Returns the address of an Account that would be deployed with the given admin signer.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _adminSigner | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getSignersOfAccount

```solidity
function getSignersOfAccount(address account) external view returns (address[] signers)
```

Returns all signers of an account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| signers | address[] | undefined |

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

### onSignerAdded

```solidity
function onSignerAdded(address _signer) external nonpayable
```

Callback function for an Account to register its signers.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |

### onSignerRemoved

```solidity
function onSignerRemoved(address _signer) external nonpayable
```

Callback function for an Account to un-register its signers.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |



## Events

### AccountCreated

```solidity
event AccountCreated(address indexed account, address indexed accountAdmin)
```

Emitted when a new Account is created.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| accountAdmin `indexed` | address | undefined |

### SignerAdded

```solidity
event SignerAdded(address indexed account, address indexed signer)
```

Emitted when a new signer is added to an Account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| signer `indexed` | address | undefined |

### SignerRemoved

```solidity
event SignerRemoved(address indexed account, address indexed signer)
```

Emitted when a new signer is added to an Account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| signer `indexed` | address | undefined |



