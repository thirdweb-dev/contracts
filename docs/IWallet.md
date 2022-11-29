# IWallet









## Methods

### deploy

```solidity
function deploy(IWallet.DeployParams params, bytes signature) external payable returns (address deployment)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| params | IWallet.DeployParams | undefined |
| signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| deployment | address | undefined |

### execute

```solidity
function execute(IWallet.TransactionParams params, bytes signature) external payable returns (bool success)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| params | IWallet.TransactionParams | undefined |
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

### updateSigner

```solidity
function updateSigner(address newSigner) external nonpayable returns (bool success)
```

Updates the signer of a smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| newSigner | address | The address to set as the signer of the smart contract. |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined |



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

### SignerUpdated

```solidity
event SignerUpdated(address prevSigner, address newSigner)
```

Emitted when the signer of the wallet is updated.



#### Parameters

| Name | Type | Description |
|---|---|---|
| prevSigner  | address | undefined |
| newSigner  | address | undefined |

### TransactionExecuted

```solidity
event TransactionExecuted(address indexed signer, address indexed target, bytes data, uint256 indexed nonce, uint256 value, uint256 txGas)
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
| txGas  | uint256 | undefined |



