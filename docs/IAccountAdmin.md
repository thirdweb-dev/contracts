# IAccountAdmin









## Methods

### addSignerToAccount

```solidity
function addSignerToAccount(address signer, bytes32 credentials) external nonpayable
```

Called by an account (itself) when a signer is added to it.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | The signer added to the account. |
| credentials | bytes32 | The credentials of the signer used with the relevant account. |

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

### getAccountForCredential

```solidity
function getAccountForCredential(address signer, bytes32 credentials) external view returns (address)
```

Returns the account associated with a particular signer-credential pair.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |
| credentials | bytes32 | undefined |

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
function relay(IAccountAdmin.RelayRequestParams params, bytes signature) external payable returns (bool success, bytes result)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| params | IAccountAdmin.RelayRequestParams | undefined |
| signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined |
| result | bytes | undefined |

### removeSignerToAccount

```solidity
function removeSignerToAccount(address signer, bytes32 credentials) external nonpayable
```

Called by an account (itself) when a signer is removed from it.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | The signer removed from the account. |
| credentials | bytes32 | The credentials of the signer used with the relevant account. |



## Events

### AccountCreated

```solidity
event AccountCreated(address indexed account, address indexed signerOfAccount, address indexed creator, bytes32 credentials)
```

Emitted when an account is created.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| signerOfAccount `indexed` | address | undefined |
| creator `indexed` | address | undefined |
| credentials  | bytes32 | undefined |

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



