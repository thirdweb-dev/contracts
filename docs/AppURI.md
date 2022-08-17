# AppURI





Thirdweb&#39;s `AppURI` is a contract extension for any contract  that wants to add an official App URI that follows the appUri spec



## Methods

### appURI

```solidity
function appURI() external view returns (string)
```



*appURI*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### setAppURI

```solidity
function setAppURI(string _uri) external nonpayable
```



*Lets a contract admin set the URI for app metadata.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _uri | string | undefined |



## Events

### AppURIUpdated

```solidity
event AppURIUpdated(string prevURI, string newURI)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prevURI  | string | undefined |
| newURI  | string | undefined |



