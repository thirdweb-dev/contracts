# AccountCore









## Methods

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### SIGNER_ROLE

```solidity
function SIGNER_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### addDeposit

```solidity
function addDeposit() external payable
```

Deposit funds for this account in Entrypoint.




### entryPoint

```solidity
function entryPoint() external view returns (contract IEntryPoint)
```

Returns the EIP 4337 entrypoint contract.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IEntryPoint | undefined |

### getDeposit

```solidity
function getDeposit() external view returns (uint256)
```

Returns the balance of the account in Entrypoint.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getNonce

```solidity
function getNonce() external view returns (uint256)
```

Return the account nonce. This method returns the next sequential nonce. For a nonce of a specific key, use `entrypoint.getNonce(account, key)`




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### initialize

```solidity
function initialize(address _defaultAdmin, bytes) external nonpayable
```

Initializes the smart contract wallet.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _defaultAdmin | address | undefined |
| _1 | bytes | undefined |

### isValidSignature

```solidity
function isValidSignature(bytes32 _hash, bytes _signature) external view returns (bytes4 magicValue)
```

See EIP-1271



#### Parameters

| Name | Type | Description |
|---|---|---|
| _hash | bytes32 | undefined |
| _signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| magicValue | bytes4 | undefined |

### isValidSigner

```solidity
function isValidSigner(address _signer) external view returns (bool)
```

Returns whether a signer is authorized to perform transactions using the wallet.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |

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

### validateUserOp

```solidity
function validateUserOp(UserOperation userOp, bytes32 userOpHash, uint256 missingAccountFunds) external nonpayable returns (uint256 validationData)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| userOp | UserOperation | undefined |
| userOpHash | bytes32 | undefined |
| missingAccountFunds | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| validationData | uint256 | undefined |

### withdrawDepositTo

```solidity
function withdrawDepositTo(address payable withdrawAddress, uint256 amount) external nonpayable
```

Withdraw funds for this account from Entrypoint.



#### Parameters

| Name | Type | Description |
|---|---|---|
| withdrawAddress | address payable | undefined |
| amount | uint256 | undefined |



## Events

### Initialized

```solidity
event Initialized(uint8 version)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### RoleGranted

```solidity
event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
```

See Permissions-RoleGranted



#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| account `indexed` | address | undefined |
| sender `indexed` | address | undefined |



