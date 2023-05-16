# DynamicAccount









## Methods

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### EXTENSION_ADMIN_ROLE

```solidity
function EXTENSION_ADMIN_ROLE() external view returns (bytes32)
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




### addExtension

```solidity
function addExtension(IExtension.Extension _extension) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _extension | IExtension.Extension | undefined |

### defaultExtension

```solidity
function defaultExtension() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### entryPoint

```solidity
function entryPoint() external view returns (contract IEntryPoint)
```

Returns the EIP 4337 entrypoint contract.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IEntryPoint | undefined |

### getAllExtensions

```solidity
function getAllExtensions() external view returns (struct IExtension.Extension[] allExtensions)
```

Returns all extensions stored. Override default lugins stored in router are          given precedence over default extensions in DefaultExtensionSet.




#### Returns

| Name | Type | Description |
|---|---|---|
| allExtensions | IExtension.Extension[] | undefined |

### getAllFunctionsOfExtension

```solidity
function getAllFunctionsOfExtension(string _extensionName) external view returns (struct IExtension.ExtensionFunction[])
```



*Returns all functions that belong to the given extension contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _extensionName | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IExtension.ExtensionFunction[] | undefined |

### getDeposit

```solidity
function getDeposit() external view returns (uint256)
```

Returns the balance of the account in Entrypoint.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getExtension

```solidity
function getExtension(string _extensionName) external view returns (struct IExtension.Extension)
```



*Returns the extension metadata and functions for a given extension.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _extensionName | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IExtension.Extension | undefined |

### getExtensionForFunction

```solidity
function getExtensionForFunction(bytes4 _functionSelector) external view returns (struct IExtension.ExtensionMetadata)
```



*Returns the extension metadata for a given function.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _functionSelector | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IExtension.ExtensionMetadata | undefined |

### getExtensionImplementation

```solidity
function getExtensionImplementation(string _extensionName) external view returns (address)
```



*Returns the extension&#39;s implementation smart contract address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _extensionName | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getImplementationForFunction

```solidity
function getImplementationForFunction(bytes4 _functionSelector) external view returns (address)
```



*Returns the extension implementation address stored in router, for the given function.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _functionSelector | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

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

### removeExtension

```solidity
function removeExtension(string _extensionName) external nonpayable
```



*Removes an existing extension from the router.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _extensionName | string | undefined |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```



*See {IERC165-supportsInterface}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| interfaceId | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### updateExtension

```solidity
function updateExtension(IExtension.Extension _extension) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _extension | IExtension.Extension | undefined |

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

### ExtensionAdded

```solidity
event ExtensionAdded(address indexed extensionAddress, bytes4 indexed functionSelector, string functionSignature)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| extensionAddress `indexed` | address | undefined |
| functionSelector `indexed` | bytes4 | undefined |
| functionSignature  | string | undefined |

### ExtensionRemoved

```solidity
event ExtensionRemoved(address indexed extensionAddress, bytes4 indexed functionSelector, string functionSignature)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| extensionAddress `indexed` | address | undefined |
| functionSelector `indexed` | bytes4 | undefined |
| functionSignature  | string | undefined |

### ExtensionUpdated

```solidity
event ExtensionUpdated(address indexed oldExtensionAddress, address indexed newExtensionAddress, bytes4 indexed functionSelector, string functionSignature)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| oldExtensionAddress `indexed` | address | undefined |
| newExtensionAddress `indexed` | address | undefined |
| functionSelector `indexed` | bytes4 | undefined |
| functionSignature  | string | undefined |

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



