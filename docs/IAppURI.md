# IAppURI





Thirdweb&#39;s `AppURI` is a contract extension for any base contracts. It lets you set a metadata URI  for you contract.



## Methods

### appURI

```solidity
function appURI() external view returns (string)
```



*Returns the metadata URI of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### setAppURI

```solidity
function setAppURI(string _uri) external nonpayable
```



*Sets contract URI for the storefront-level metadata of the contract.       Only module admin can call this function.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _uri | string | undefined |



## Events

### AppURIUpdated

```solidity
event AppURIUpdated(string prevURI, string newURI)
```



*Emitted when the contract URI is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| prevURI  | string | undefined |
| newURI  | string | undefined |



