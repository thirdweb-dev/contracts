# AccountAdmin









## Methods

### accountImplementation

```solidity
function accountImplementation() external view returns (address)
```

Implementation address for `Account`.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### addSignerToAccount

```solidity
function addSignerToAccount(address _signer, bytes32 _accountId) external nonpayable
```

Called by an account (itself) when a signer is added to it.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |
| _accountId | bytes32 | undefined |

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

### getAccount

```solidity
function getAccount(address _signer, bytes32 _accountId) external view returns (address)
```

Returns the account associated with a particular signer-accountId pair.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |
| _accountId | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getAllAccountsOfSigner

```solidity
function getAllAccountsOfSigner(address _signer) external view returns (address[])
```

Returns all accounts that a signer is a part of.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address[] | undefined |

### getAllSignersOfAccount

```solidity
function getAllSignersOfAccount(address _account) external view returns (address[])
```

Returns all signers that are part of an account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address[] | undefined |

### initialize

```solidity
function initialize(address[] _trustedForwarders) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _trustedForwarders | address[] | undefined |

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

### relay

```solidity
function relay(address _signer, bytes32 _accountId, uint256 _value, uint256 _gas, bytes _data) external payable returns (bool, bytes)
```

Calls an account with transaction data.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |
| _accountId | bytes32 | undefined |
| _value | uint256 | undefined |
| _gas | uint256 | undefined |
| _data | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |
| _1 | bytes | undefined |

### removeSignerToAccount

```solidity
function removeSignerToAccount(address _signer, bytes32 _accountId) external nonpayable
```

Called by an account (itself) when a signer is removed from it.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |
| _accountId | bytes32 | undefined |



## Events

### AccountCreated

```solidity
event AccountCreated(address indexed account, address indexed signerOfAccount, address indexed creator, bytes32 accountId)
```

Emitted when an account is created.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| signerOfAccount `indexed` | address | undefined |
| creator `indexed` | address | undefined |
| accountId  | bytes32 | undefined |

### CallResult

```solidity
event CallResult(address indexed signer, address indexed account, bool success)
```

Emitted on a call to an account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer `indexed` | address | undefined |
| account `indexed` | address | undefined |
| success  | bool | undefined |

### Initialized

```solidity
event Initialized(uint8 version)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### SignerAdded

```solidity
event SignerAdded(address signer, address account, bytes32 pairHash)
```

Emitted when a signer is added to an account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer  | address | undefined |
| account  | address | undefined |
| pairHash  | bytes32 | undefined |

### SignerRemoved

```solidity
event SignerRemoved(address signer, address account, bytes32 pairHash)
```

Emitted when a signer is removed from an account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer  | address | undefined |
| account  | address | undefined |
| pairHash  | bytes32 | undefined |



