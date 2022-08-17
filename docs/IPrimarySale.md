# IPrimarySale





Thirdweb&#39;s `Primary` is a contract extension to be used with any base contract. It exposes functions for setting and reading  the recipient of primary sales, and lets the inheriting contract perform conditional logic that uses information about  primary sales, if desired.



## Methods

### primarySaleRecipient

```solidity
function primarySaleRecipient() external view returns (address)
```



*The adress that receives all primary sales value.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### setPrimarySaleRecipient

```solidity
function setPrimarySaleRecipient(address _saleRecipient) external nonpayable
```



*Lets a module admin set the default recipient of all primary sales.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _saleRecipient | address | undefined |



## Events

### PrimarySaleRecipientUpdated

```solidity
event PrimarySaleRecipientUpdated(address indexed recipient)
```



*Emitted when a new sale recipient is set.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| recipient `indexed` | address | undefined |



