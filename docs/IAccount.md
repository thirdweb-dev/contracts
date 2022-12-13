# IAccount









## Methods

### addSigner

```solidity
function addSigner(IAccount.SignerUpdateParams params, bytes signature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| params | IAccount.SignerUpdateParams | undefined |
| signature | bytes | undefined |

### deploy

```solidity
function deploy(IAccount.DeployParams params, bytes signature) external payable returns (address deployment)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| params | IAccount.DeployParams | undefined |
| signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| deployment | address | undefined |

### execute

```solidity
function execute(IAccount.TransactionParams params, bytes signature) external payable returns (bool success)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| params | IAccount.TransactionParams | undefined |
| signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined |

### isValidSignature

```solidity
function isValidSignature(bytes32 _hash, bytes _signature) external view returns (bytes4)
```



*Should return whether the signature provided is valid for the provided hash*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _hash | bytes32 | Hash of the data to be signed |
| _signature | bytes | Signature byte array associated with _hash MUST return the bytes4 magic value 0x1626ba7e when function passes. MUST NOT modify state (using STATICCALL for solc &lt; 0.5, view modifier for solc &gt; 0.5) MUST allow external calls |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### removeSigner

```solidity
function removeSigner(IAccount.SignerUpdateParams params, bytes signature) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| params | IAccount.SignerUpdateParams | undefined |
| signature | bytes | undefined |



## Events

### ContractDeployed

```solidity
event ContractDeployed(address indexed deployment)
```

Emitted when the wallet deploys a smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| deployment `indexed` | address | undefined |

### SignerAdded

```solidity
event SignerAdded(address signer)
```

Emitted when the signer is added to the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer  | address | undefined |

### SignerRemoved

```solidity
event SignerRemoved(address signer)
```

Emitted when the signer is removed from the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer  | address | undefined |

### TransactionExecuted

```solidity
event TransactionExecuted(address indexed signer, address indexed target, bytes data, uint256 indexed nonce, uint256 value, uint256 gas)
```

Emitted when a wallet performs a call.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer `indexed` | address | undefined |
| target `indexed` | address | undefined |
| data  | bytes | undefined |
| nonce `indexed` | uint256 | undefined |
| value  | uint256 | undefined |
| gas  | uint256 | undefined |



