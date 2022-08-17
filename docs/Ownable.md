# Ownable



> Ownable

Thirdweb&#39;s `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading           who the &#39;owner&#39; of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses           information about who the contract&#39;s owner is.



## Methods

### owner

```solidity
function owner() external view returns (address)
```

Returns the owner of the contract.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### setOwner

```solidity
function setOwner(address _newOwner) external nonpayable
```

Lets an authorized wallet set a new owner for the contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _newOwner | address | The address to set as the new owner of the contract. |



## Events

### OwnerUpdated

```solidity
event OwnerUpdated(address indexed prevOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prevOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |



