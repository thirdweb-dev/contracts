# IByocRegistry









## Methods

### deployInstance

```solidity
function deployInstance(address publisher, uint256 contractId, bytes creationCode, bytes data, bytes32 salt, uint256 _value) external nonpayable returns (address deployedAddress)
```

Deploys an instance of a published contract directly.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | undefined
| contractId | uint256 | undefined
| creationCode | bytes | undefined
| data | bytes | undefined
| salt | bytes32 | undefined
| _value | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| deployedAddress | address | undefined

### deployInstanceProxy

```solidity
function deployInstanceProxy(address publisher, uint256 contractId, bytes data, bytes32 salt) external nonpayable returns (address deployedAddress)
```

Deploys a clone pointing to an implementation of a published contract directly.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | undefined
| contractId | uint256 | undefined
| data | bytes | undefined
| salt | bytes32 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| deployedAddress | address | undefined

### getPublishedContracts

```solidity
function getPublishedContracts(address publisher) external view returns (struct IByocRegistry.CustomContract[])
```

Returns all contracts published by a publisher.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IByocRegistry.CustomContract[] | undefined

### publishContract

```solidity
function publishContract(address publisher, string publishMetadataHash, bytes creationCodeHash, address implementation) external nonpayable returns (uint256 contractId)
```

Add a contract to a publisher&#39;s set of published contracts.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | undefined
| publishMetadataHash | string | undefined
| creationCodeHash | bytes | undefined
| implementation | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| contractId | uint256 | undefined

### unpublishContract

```solidity
function unpublishContract(address publisher, uint256 contractId) external nonpayable
```

Remove a contract from a publisher&#39;s set of published contracts.



#### Parameters

| Name | Type | Description |
|---|---|---|
| publisher | address | undefined
| contractId | uint256 | undefined




