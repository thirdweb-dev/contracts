# ThirdwebContract









## Methods

### contractURI

```solidity
function contractURI() external view returns (string)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined

### getPublishMetadataUri

```solidity
function getPublishMetadataUri() external view returns (string)
```



*Returns the publish metadata for this contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined

### owner

```solidity
function owner() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

### setContractURI

```solidity
function setContractURI(string _uri) external nonpayable
```



*Lets a contract admin set the URI for contract-level metadata.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _uri | string | undefined

### setOwner

```solidity
function setOwner(address _newOwner) external nonpayable
```



*Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _newOwner | address | undefined

### setThirdwebInfo

```solidity
function setThirdwebInfo(ThirdwebContract.ThirdwebInfo _thirdwebInfo) external nonpayable
```



*Initializes the publish metadata and contract metadata at deploy time.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _thirdwebInfo | ThirdwebContract.ThirdwebInfo | undefined



## Events

### OwnerUpdated

```solidity
event OwnerUpdated(address prevOwner, address newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prevOwner  | address | undefined |
| newOwner  | address | undefined |



