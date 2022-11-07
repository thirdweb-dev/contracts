# IOwnable





Thirdweb&#39;s (EIP 173) `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting  and reading who the &#39;owner&#39; of the inheriting smart contract is, and lets the inheriting contract perform conditional logic  that uses information about who the contract&#39;s owner is.



## Methods

### owner

```solidity
function owner() external view returns (address ownerAddr)
```

Get the address of the owner




#### Returns

| Name | Type | Description |
|---|---|---|
| ownerAddr | address | address of the owner. |

### transferOwnership

```solidity
function transferOwnership(address _newOwner) external nonpayable
```

Set the address of the new owner of the contract

*Set _newOwner to address(0) to renounce any ownership.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _newOwner | address | The address of the new owner of the contract |



## Events

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```



*This emits when ownership of a contract changes.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |



