# SenderCreator





helper contract for EntryPoint, to call userOp.initCode from a &quot;neutral&quot; address, which is explicitly not the entryPoint itself.



## Methods

### createSender

```solidity
function createSender(bytes initCode) external nonpayable returns (address sender)
```

call the &quot;initCode&quot; factory to create and return the sender account address



#### Parameters

| Name | Type | Description |
|---|---|---|
| initCode | bytes | the initCode value from a UserOp. contains 20 bytes of factory address, followed by calldata |

#### Returns

| Name | Type | Description |
|---|---|---|
| sender | address | the returned address of the created account, or zero address on failure. |



## Events

### FactoryAddress

```solidity
event FactoryAddress(address factory)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| factory  | address | undefined |



