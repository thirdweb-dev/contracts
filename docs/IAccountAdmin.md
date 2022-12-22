# IAccountAdmin









## Methods

### addSignerToAccount

```solidity
function addSignerToAccount(address signer, bytes32 accountId) external nonpayable
```

Called by an account (itself) when a signer is added to it.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | The signer added to the account. |
| accountId | bytes32 | The accountId of the signer used with the relevant account. |

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

### getAccount

```solidity
function getAccount(address signer, bytes32 accountId) external view returns (address)
```

Returns the account associated with a particular signer-accountId pair.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |
| accountId | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getAllAccountsOfSigner

```solidity
function getAllAccountsOfSigner(address signer) external view returns (address[] accounts)
```

Returns all accounts that a signer is a part of.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| accounts | address[] | undefined |

### getAllSignersOfAccount

```solidity
function getAllSignersOfAccount(address account) external view returns (address[] signers)
```

Returns all signers that are part of an account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| signers | address[] | undefined |

### relay

```solidity
function relay(IAccountAdmin.RelayRequestParams params) external payable returns (bool success, bytes result)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| params | IAccountAdmin.RelayRequestParams | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined |
| result | bytes | undefined |

### removeSignerToAccount

```solidity
function removeSignerToAccount(address signer, bytes32 accountId) external nonpayable
```

Called by an account (itself) when a signer is removed from it.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | The signer removed from the account. |
| accountId | bytes32 | The accountId of the signer used with the relevant account. |



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



