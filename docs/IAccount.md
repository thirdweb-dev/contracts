# IAccount









## Methods

### addAdmin

```solidity
function addAdmin(address signer, bytes32 accountId) external nonpayable
```

Adds an admin to the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | The address to make an admin of the Account. |
| accountId | bytes32 | The accountId for the address; must be unique for the signer in the associated AccountAdmin. |

### addSigner

```solidity
function addSigner(address signer, bytes32 accountId) external nonpayable
```

Adds a signer to the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | An address to add as a signer to the Account. |
| accountId | bytes32 | The accountId for the address; must be unique for the signer in the associated AccountAdmin. |

### approveSignerForContract

```solidity
function approveSignerForContract(address signer, address target) external nonpayable
```

Approves a signer to be able to call any function on `target` smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | The signer to approve. |
| target | address | The contract address to approve the signer for. |

### approveSignerForFunction

```solidity
function approveSignerForFunction(address signer, bytes4 selector) external nonpayable
```

Approves a signer to be able to call `selector` function on any smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | The signer to approve. |
| selector | bytes4 | The function selector to approve the signer for. |

### approveSignerForTarget

```solidity
function approveSignerForTarget(address signer, bytes4 selector, address target) external nonpayable
```

Approves a signer to be able to call `_selector` function on `_target` smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | The signer to approve. |
| selector | bytes4 | The function selector to approve the signer for. |
| target | address | The contract address to approve the signer for. |

### deploy

```solidity
function deploy(bytes bytecode, bytes32 salt, uint256 value) external payable returns (address deployment)
```

Deploys a smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| bytecode | bytes | The bytecode of the contract to deploy. |
| salt | bytes32 | The salt to use in the CREATE2 deployment of the contract. |
| value | uint256 | The value to send to the contract at construction time. |

#### Returns

| Name | Type | Description |
|---|---|---|
| deployment | address | undefined |

### disapproveSignerForContract

```solidity
function disapproveSignerForContract(address signer, address target) external nonpayable
```

Disapproves a signer from being able to call arbitrary function on `_target` smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | The signer to remove approval for. |
| target | address | The contract address for which to remove the approval of the signer. |

### disapproveSignerForFunction

```solidity
function disapproveSignerForFunction(address signer, bytes4 selector) external nonpayable
```

Disapproves a signer from being able to call `_selector` function on arbitrary smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | The signer to remove approval for. |
| selector | bytes4 | The function selector for which to remove the approval of the signer. |

### disapproveSignerForTarget

```solidity
function disapproveSignerForTarget(address signer, bytes4 selector, address target) external nonpayable
```

Removes approval of a signer from being able to call `_selector` function on `_target` smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | The signer to remove approval for. |
| selector | bytes4 | The function selector for which to remove the approval of the signer. |
| target | address | The contract address for which to remove the approval of the signer. |

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

### getAllApprovedContracts

```solidity
function getAllApprovedContracts(address signer) external view returns (address[] contracts)
```

Returns all contract targets approved for a given signer.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| contracts | address[] | undefined |

### getAllApprovedFunctions

```solidity
function getAllApprovedFunctions(address signer) external view returns (bytes4[] functions)
```

Returns all function targets approved for a given signer.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| functions | bytes4[] | undefined |

### getAllApprovedTargets

```solidity
function getAllApprovedTargets(address signer) external view returns (struct IAccount.CallTarget[] approvedTargets)
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
function removeAdmin(address signer, bytes32 accountId) external nonpayable
```

Removes an admin from the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | The address to remove as an admin of the Account. |
| accountId | bytes32 | The accountId for the address. |

### removeSigner

```solidity
function removeSigner(address signer, bytes32 accountId) external nonpayable
```

Removes a signer from the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer | address | An address to remove as a signer to the Account. |
| accountId | bytes32 | The accountId for the address. |



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

### ContractApprovedForSigner

```solidity
event ContractApprovedForSigner(address indexed signer, address indexed targetContract, bool approval)
```

Emitted when a signer is approved to call arbitrary function on `target` smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer `indexed` | address | undefined |
| targetContract `indexed` | address | undefined |
| approval  | bool | undefined |

### ContractDeployed

```solidity
event ContractDeployed(address indexed deployment)
```

Emitted when the wallet deploys a smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| deployment `indexed` | address | undefined |

### FunctionApprovedForSigner

```solidity
event FunctionApprovedForSigner(address indexed signer, bytes4 indexed selector, bool approval)
```

Emitted when a signer is approved to call `selector` function on arbitrary smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer `indexed` | address | undefined |
| selector `indexed` | bytes4 | undefined |
| approval  | bool | undefined |

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

### TargetApprovedForSigner

```solidity
event TargetApprovedForSigner(address indexed signer, bytes4 indexed selector, address indexed target, bool isApproved)
```

Emitted when a signer is approved to call `selector` function on `target` smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer `indexed` | address | undefined |
| selector `indexed` | bytes4 | undefined |
| target `indexed` | address | undefined |
| isApproved  | bool | undefined |

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



