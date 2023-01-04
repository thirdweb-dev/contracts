# OperatorFilterer



> OperatorFilterer

Abstract contract whose constructor automatically registers and optionally subscribes to or copies another         registrant&#39;s entries in the OperatorFilterRegistry.

*This smart contract is meant to be inherited by token contracts so they can use the following:         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.*

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


