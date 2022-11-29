# Wallet





Basic actions:      - Deploy smart contracts ✅      - Make transactions on contracts ✅      - Sign messages ✅      - Own assets ✅



## Methods

### controller

```solidity
function controller() external view returns (address)
```

The admin of the wallet; the only address that is a valid `msg.sender` in this contract.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### deploy

```solidity
function deploy(IWallet.DeployParams _params, bytes _signature) external payable returns (address deployment)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _params | IWallet.DeployParams | undefined |
| _signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| deployment | address | undefined |

### execute

```solidity
function execute(IWallet.TransactionParams _params, bytes _signature) external payable returns (bool success)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _params | IWallet.TransactionParams | undefined |
| _signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined |

### isValidSignature

```solidity
function isValidSignature(bytes32 _hash, bytes _signature) external view returns (bytes4)
```

See EIP-1271. Returns whether a signature is a valid signature made on behalf of this contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _hash | bytes32 | undefined |
| _signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### nonce

```solidity
function nonce() external view returns (uint256)
```

The nonce of the wallet.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### onERC1155BatchReceived

```solidity
function onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) external nonpayable returns (bytes4)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256[] | undefined |
| _3 | uint256[] | undefined |
| _4 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### onERC1155Received

```solidity
function onERC1155Received(address, address, uint256, uint256, bytes) external nonpayable returns (bytes4)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256 | undefined |
| _3 | uint256 | undefined |
| _4 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) external nonpayable returns (bytes4)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256 | undefined |
| _3 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### signer

```solidity
function signer() external view returns (address)
```

The signer of the wallet; a signature from this signer must be provided to execute with the wallet.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### updateSigner

```solidity
function updateSigner(address _newSigner) external nonpayable returns (bool success)
```

Updates the signer of this contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _newSigner | address | undefined |

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



