# ForwarderBiconomyEOAOnly









## Methods

### EIP712_DOMAIN_TYPE

```solidity
function EIP712_DOMAIN_TYPE() external view returns (string)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### REQUEST_TYPEHASH

```solidity
function REQUEST_TYPEHASH() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### domains

```solidity
function domains(bytes32) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### executeEIP712

```solidity
function executeEIP712(ERC20ForwardRequestTypes.ERC20ForwardRequest req, bytes32 domainSeparator, bytes sig) external nonpayable returns (bool success, bytes ret)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| req | ERC20ForwardRequestTypes.ERC20ForwardRequest | undefined |
| domainSeparator | bytes32 | undefined |
| sig | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined |
| ret | bytes | undefined |

### executePersonalSign

```solidity
function executePersonalSign(ERC20ForwardRequestTypes.ERC20ForwardRequest req, bytes sig) external nonpayable returns (bool success, bytes ret)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| req | ERC20ForwardRequestTypes.ERC20ForwardRequest | undefined |
| sig | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined |
| ret | bytes | undefined |

### getNonce

```solidity
function getNonce(address from, uint256 batchId) external view returns (uint256)
```



*returns a value from the nonces 2d mapping*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | : the user address |
| batchId | uint256 | : the key of the user&#39;s batch being queried |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | nonce : the number of transaction made within said batch |

### getOwner

```solidity
function getOwner() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | the address of the owner. |

### isOwner

```solidity
function isOwner() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | true if `msg.sender` is the owner of the contract. |

### registerDomainSeparator

```solidity
function registerDomainSeparator(string name, string version) external nonpayable
```



*registers domain seperators, maintaining that all domain seperators used for EIP712 forward requests use... ... the address of this contract and the chainId of the chain this contract is deployed to*

#### Parameters

| Name | Type | Description |
|---|---|---|
| name | string | : name of dApp/dApp fee proxy |
| version | string | : version of dApp/dApp fee proxy |

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```

Renouncing to ownership will leave the contract without an owner. It will not be possible to call the functions with the `onlyOwner` modifier anymore.

*Allows the current owner to relinquish control of the contract.*


### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Allows the current owner to transfer control of the contract to a newOwner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | The address to transfer ownership to. |

### verifyEIP712

```solidity
function verifyEIP712(ERC20ForwardRequestTypes.ERC20ForwardRequest req, bytes32 domainSeparator, bytes sig) external view
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| req | ERC20ForwardRequestTypes.ERC20ForwardRequest | undefined |
| domainSeparator | bytes32 | undefined |
| sig | bytes | undefined |

### verifyPersonalSign

```solidity
function verifyPersonalSign(ERC20ForwardRequestTypes.ERC20ForwardRequest req, bytes sig) external view
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| req | ERC20ForwardRequestTypes.ERC20ForwardRequest | undefined |
| sig | bytes | undefined |



## Events

### DomainRegistered

```solidity
event DomainRegistered(bytes32 indexed domainSeparator, bytes domainValue)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| domainSeparator `indexed` | bytes32 | undefined |
| domainValue  | bytes | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |



