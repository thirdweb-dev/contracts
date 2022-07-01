# ThirdwebContract









## Methods

### owner

```solidity
function owner() external view returns (address)
```



*Returns the owner of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

### setOwner

```solidity
function setOwner(address _newOwner) external nonpayable
```



*Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _newOwner | address | undefined

### tw_initializeOwner

```solidity
function tw_initializeOwner(address deployer) external nonpayable
```



*Initializes the owner of the contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| deployer | address | undefined



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



## Errors

### Ownable__NotAuthorized

```solidity
error Ownable__NotAuthorized()
```



*Emitted when an unauthorized caller tries to set the owner.*



