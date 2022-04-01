# ByocRegistry









## Methods

### deployInstance

```solidity
function deployInstance(address _publisher, uint256 _contractId, bytes _creationCode, bytes _data, bytes32 _salt, uint256 _value) external nonpayable returns (address deployedAddress)
```

Deploys an instance of a published contract directly.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _publisher | address | undefined
| _contractId | uint256 | undefined
| _creationCode | bytes | undefined
| _data | bytes | undefined
| _salt | bytes32 | undefined
| _value | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| deployedAddress | address | undefined

### deployInstanceProxy

```solidity
function deployInstanceProxy(address _publisher, uint256 _contractId, bytes _data, bytes32 _salt) external nonpayable returns (address deployedAddress)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _publisher | address | undefined
| _contractId | uint256 | undefined
| _data | bytes | undefined
| _salt | bytes32 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| deployedAddress | address | undefined

### getPublishedContracts

```solidity
function getPublishedContracts(address _publisher) external view returns (struct IByocRegistry.CustomContract[] published)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _publisher | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| published | IByocRegistry.CustomContract[] | undefined

### publishContract

```solidity
function publishContract(address _publisher, string _publishMetadataHash, bytes _creationCodeHash, address _implementation) external nonpayable returns (uint256 contractId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _publisher | address | undefined
| _publishMetadataHash | string | undefined
| _creationCodeHash | bytes | undefined
| _implementation | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| contractId | uint256 | undefined

### unpublishContract

```solidity
function unpublishContract(address _publisher, uint256 _contractId) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _publisher | address | undefined
| _contractId | uint256 | undefined




