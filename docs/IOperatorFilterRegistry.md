# IOperatorFilterRegistry

*thirdweb*







## Methods

### codeHashOf

```solidity
function codeHashOf(address addr) external nonpayable returns (bytes32)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| addr | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### copyEntriesOf

```solidity
function copyEntriesOf(address registrant, address registrantToCopy) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |
| registrantToCopy | address | undefined |

### filteredCodeHashAt

```solidity
function filteredCodeHashAt(address registrant, uint256 index) external nonpayable returns (bytes32)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |
| index | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### filteredCodeHashes

```solidity
function filteredCodeHashes(address addr) external nonpayable returns (bytes32[])
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| addr | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32[] | undefined |

### filteredOperatorAt

```solidity
function filteredOperatorAt(address registrant, uint256 index) external nonpayable returns (address)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |
| index | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### filteredOperators

```solidity
function filteredOperators(address addr) external nonpayable returns (address[])
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| addr | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address[] | undefined |

### isCodeHashFiltered

```solidity
function isCodeHashFiltered(address registrant, bytes32 codeHash) external nonpayable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |
| codeHash | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isCodeHashOfFiltered

```solidity
function isCodeHashOfFiltered(address registrant, address operatorWithCode) external nonpayable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |
| operatorWithCode | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isOperatorAllowed

```solidity
function isOperatorAllowed(address registrant, address operator) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |
| operator | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isOperatorFiltered

```solidity
function isOperatorFiltered(address registrant, address operator) external nonpayable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |
| operator | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isRegistered

```solidity
function isRegistered(address addr) external nonpayable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| addr | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### register

```solidity
function register(address registrant) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |

### registerAndCopyEntries

```solidity
function registerAndCopyEntries(address registrant, address registrantToCopy) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |
| registrantToCopy | address | undefined |

### registerAndSubscribe

```solidity
function registerAndSubscribe(address registrant, address subscription) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |
| subscription | address | undefined |

### subscribe

```solidity
function subscribe(address registrant, address registrantToSubscribe) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |
| registrantToSubscribe | address | undefined |

### subscriberAt

```solidity
function subscriberAt(address registrant, uint256 index) external nonpayable returns (address)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |
| index | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### subscribers

```solidity
function subscribers(address registrant) external nonpayable returns (address[])
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address[] | undefined |

### subscriptionOf

```solidity
function subscriptionOf(address addr) external nonpayable returns (address registrant)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| addr | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |

### unregister

```solidity
function unregister(address addr) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| addr | address | undefined |

### unsubscribe

```solidity
function unsubscribe(address registrant, bool copyExistingEntries) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |
| copyExistingEntries | bool | undefined |

### updateCodeHash

```solidity
function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |
| codehash | bytes32 | undefined |
| filtered | bool | undefined |

### updateCodeHashes

```solidity
function updateCodeHashes(address registrant, bytes32[] codeHashes, bool filtered) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |
| codeHashes | bytes32[] | undefined |
| filtered | bool | undefined |

### updateOperator

```solidity
function updateOperator(address registrant, address operator, bool filtered) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |
| operator | address | undefined |
| filtered | bool | undefined |

### updateOperators

```solidity
function updateOperators(address registrant, address[] operators, bool filtered) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| registrant | address | undefined |
| operators | address[] | undefined |
| filtered | bool | undefined |




