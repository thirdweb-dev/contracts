# DefaultOperatorFilterer



> DefaultOperatorFilterer

Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.



## Methods

### OPERATOR_FILTER_REGISTRY

```solidity
function OPERATOR_FILTER_REGISTRY() external view returns (contract IOperatorFilterRegistry)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IOperatorFilterRegistry | undefined |

### operatorRestriction

```solidity
function operatorRestriction() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### setOperatorRestriction

```solidity
function setOperatorRestriction(bool _restriction) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _restriction | bool | undefined |

### subscribeToRegistry

```solidity
function subscribeToRegistry(address _subscription) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _subscription | address | undefined |



## Events

### OperatorRestriction

```solidity
event OperatorRestriction(bool restriction)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| restriction  | bool | undefined |



## Errors

### OperatorNotAllowed

```solidity
error OperatorNotAllowed(address operator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | undefined |


