# ISignatureAction









## Methods

### verify

```solidity
function verify(ISignatureAction.GenericRequest req, bytes signature) external view returns (bool success, address signer)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| req | ISignatureAction.GenericRequest | undefined |
| signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined |
| signer | address | undefined |



## Events

### RequestExecuted

```solidity
event RequestExecuted(address indexed user, address indexed signer, ISignatureAction.GenericRequest _req)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| user `indexed` | address | undefined |
| signer `indexed` | address | undefined |
| _req  | ISignatureAction.GenericRequest | undefined |



