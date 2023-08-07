# IERC6551Account







*the ERC-165 identifier for this interface is `0xeff4d378`*

## Methods

### executeCall

```solidity
function executeCall(address to, uint256 value, bytes data) external payable returns (bytes)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | undefined |
| value | uint256 | undefined |
| data | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

### nonce

```solidity
function nonce() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### owner

```solidity
function owner() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### token

```solidity
function token() external view returns (uint256 chainId, address tokenContract, uint256 tokenId)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| chainId | uint256 | undefined |
| tokenContract | address | undefined |
| tokenId | uint256 | undefined |



## Events

### TransactionExecuted

```solidity
event TransactionExecuted(address indexed target, uint256 indexed value, bytes data)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| target `indexed` | address | undefined |
| value `indexed` | uint256 | undefined |
| data  | bytes | undefined |



