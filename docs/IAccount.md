# IAccount









## Methods

### addAdmin

```solidity
function addAdmin(address signer, bytes32 credentials) external nonpayable
```

Adds an admin to the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |
| credentials | bytes32 | undefined |

### addSigner

```solidity
function addSigner(address signer, bytes32 credentials) external nonpayable
```

Adds a signer to the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |
| credentials | bytes32 | undefined |

### approveSignerFor

```solidity
function approveSignerFor(address signer, bytes4 selector, address target) external nonpayable
```

Approves a signer to be able to call `_selector` function on `_target` smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |
| selector | bytes4 | undefined |
| target | address | undefined |

### deploy

```solidity
function deploy(bytes bytecode, bytes32 salt, uint256 value) external payable returns (address deployment)
```

Deploys a smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| bytecode | bytes | undefined |
| salt | bytes32 | undefined |
| value | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| deployment | address | undefined |

### disapproveSignerFor

```solidity
function disapproveSignerFor(address signer, bytes4 selector, address target) external nonpayable
```

Disapproves a signer from being able to call `_selector` function on `_target` smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |
| selector | bytes4 | undefined |
| target | address | undefined |

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

### getAllApprovedForSigner

```solidity
function getAllApprovedForSigner(address signer) external view returns (struct IAccount.CallTarget[] approvedTargets)
```

Returns all call targets approved for a given signer.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| approvedTargets | IAccount.CallTarget[] | undefined |

### isValidSignature

```solidity
function isValidSignature(bytes32 hash, bytes signature) external view returns (bytes4)
```



*Should return whether the signature provided is valid for the provided hash*

#### Parameters

| Name | Type | Description |
|---|---|---|
| hash | bytes32 | Hash of the data to be signed |
| signature | bytes | Signature byte array associated with _hash MUST return the bytes4 magic value 0x1626ba7e when function passes. MUST NOT modify state (using STATICCALL for solc &lt; 0.5, view modifier for solc &gt; 0.5) MUST allow external calls |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### removeAdmin

```solidity
function removeAdmin(address signer, bytes32 credentials) external nonpayable
```

Removes an admin from the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |
| credentials | bytes32 | undefined |

### removeSigner

```solidity
function removeSigner(address signer, bytes32 credentials) external nonpayable
```

Removes a signer from the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |
| credentials | bytes32 | undefined |



## Events

### AdminAdded

```solidity
event AdminAdded(address signer)
```

Emitted when an admin is added to the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer  | address | undefined |

### AdminRemoved

```solidity
event AdminRemoved(address signer)
```

Emitted when an admin is removed from the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer  | address | undefined |

### ApprovalForSigner

```solidity
event ApprovalForSigner(address indexed signer, bytes4 indexed selector, address indexed target, bool isApproved)
```

Emitted when a signer is approved to call `_selector` function on `_target` smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer `indexed` | address | undefined |
| selector `indexed` | bytes4 | undefined |
| target `indexed` | address | undefined |
| isApproved  | bool | undefined |

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

Emitted when a signer is added to the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer  | address | undefined |

### SignerRemoved

```solidity
event SignerRemoved(address signer)
```

Emitted when a signer is removed from the account.



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



