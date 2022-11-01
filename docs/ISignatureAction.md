# ISignatureAction





thirdweb&#39;s `SignatureAction` extension smart contract can be used with any base smart contract. It provides a generic  payload struct that can be signed by an authorized wallet and verified by the contract. The bytes `data` field provided  in the payload can be abi encoded &lt;-&gt; decoded to use `SignatureContract` for any authorized signature action.



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

Emitted when a payload is verified and executed.



#### Parameters

| Name | Type | Description |
|---|---|---|
| user `indexed` | address | undefined |
| signer `indexed` | address | undefined |
| _req  | ISignatureAction.GenericRequest | undefined |



