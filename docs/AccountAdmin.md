# AccountAdmin





- One Signer can be a part of many Accounts.  - One Account can have many Signers.  - A Signer-Credential pair hash can only be used/associated with one unique account.    i.e. a Signer must use unique credentials for each Account it wants to be a part of.  - How does data fetching work?      - Fetch all accounts for a single signer.      - Fetch all signers for a single account.      - Fetch the unique account for a signer-credential pair.



## Methods

### addSignerToAccount

```solidity
function addSignerToAccount(address _signer, bytes32 _credentials) external nonpayable
```

Called by an account (itself) when a signer is added to it.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |
| _credentials | bytes32 | undefined |

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

### getAccountForCredential

```solidity
function getAccountForCredential(address _signer, bytes32 _credentials) external view returns (address)
```

Returns the account associated with a particular signer-credential pair.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |
| _credentials | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getAllAccountsOfSigner

```solidity
function getAllAccountsOfSigner(address _signer) external view returns (address[] accounts)
```

Returns all accounts that a signer is a part of.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| accounts | address[] | undefined |

### getAllSignersOfAccount

```solidity
function getAllSignersOfAccount(address _account) external view returns (address[] signers)
```

Returns all signers that are part of an account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| signers | address[] | undefined |

### isAssociatedAccount

```solidity
function isAssociatedAccount(address) external view returns (bool)
```



*Address =&gt; whether the address is of an account created via this admin contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### relay

```solidity
function relay(IAccountAdmin.RelayRequestParams _params, bytes _signature) external payable returns (bool, bytes)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _params | IAccountAdmin.RelayRequestParams | undefined |
| _signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |
| _1 | bytes | undefined |

### removeSignerToAccount

```solidity
function removeSignerToAccount(address _signer, bytes32 _credentials) external nonpayable
```

Called by an account (itself) when a signer is removed from it.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |
| _credentials | bytes32 | undefined |



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



