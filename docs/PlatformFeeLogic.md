# PlatformFeeLogic

*thirdweb.com*

> Platform Fee

Thirdweb&#39;s `PlatformFee` is a contract extension to be used with any base contract. It exposes functions for setting and reading           the recipient of platform fee and the platform fee basis points, and lets the inheriting contract perform conditional logic           that uses information about platform fees, if desired.



## Methods

### getPlatformFeeInfo

```solidity
function getPlatformFeeInfo() external view returns (address, uint16)
```



*Returns the platform fee recipient and bps.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | uint16 | undefined |

### setPlatformFeeInfo

```solidity
function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external nonpayable
```

Updates the platform fee recipient and bps.

*Caller should be authorized to set platform fee info.                  See {_canSetPlatformFeeInfo}.                  Emits {PlatformFeeInfoUpdated Event}; See {_setupPlatformFeeInfo}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _platformFeeRecipient | address | Address to be set as new platformFeeRecipient. |
| _platformFeeBps | uint256 | Updated platformFeeBps. |



## Events

### FlatPlatformFeeUpdated

```solidity
event FlatPlatformFeeUpdated(address platformFeeRecipient, uint256 flatFee)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| platformFeeRecipient  | address | undefined |
| flatFee  | uint256 | undefined |

### PlatformFeeInfoUpdated

```solidity
event PlatformFeeInfoUpdated(address indexed platformFeeRecipient, uint256 platformFeeBps)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| platformFeeRecipient `indexed` | address | undefined |
| platformFeeBps  | uint256 | undefined |

### PlatformFeeTypeUpdated

```solidity
event PlatformFeeTypeUpdated(enum IPlatformFee.PlatformFeeType feeType)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| feeType  | enum IPlatformFee.PlatformFeeType | undefined |



