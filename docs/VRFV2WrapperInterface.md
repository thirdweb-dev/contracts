# VRFV2WrapperInterface









## Methods

### calculateRequestPrice

```solidity
function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256)
```

Calculates the price of a VRF request with the given callbackGasLimit at the currentblock.

*This function relies on the transaction gas price which is not automatically set duringsimulation. To estimate the price at a specific gas price, use the estimatePrice function.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _callbackGasLimit | uint32 | is the gas limit used to estimate the price. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### estimateRequestPrice

```solidity
function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256)
```

Estimates the price of a VRF request with a specific gas limit and gas price.

*This is a convenience function that can be called in simulation to better understandpricing.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _callbackGasLimit | uint32 | is the gas limit used to estimate the price. |
| _requestGasPriceWei | uint256 | is the gas price in wei used for the estimation. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### lastRequestId

```solidity
function lastRequestId() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | the request ID of the most recent VRF V2 request made by this wrapper. This should only be relied option within the same transaction that the request was made. |




