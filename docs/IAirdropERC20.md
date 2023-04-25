# IAirdropERC20





Thirdweb&#39;s `Airdrop` contracts provide a lightweight and easy to use mechanism  to drop tokens.  `AirdropERC20` contract is an airdrop contract for ERC20 tokens. It follows a  push mechanism for transfer of tokens to intended recipients.



## Methods

### addRecipients

```solidity
function addRecipients(IAirdropERC20.AirdropContent[] _contents) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _contents | IAirdropERC20.AirdropContent[] | undefined |

### airdrop

```solidity
function airdrop(IAirdropERC20.AirdropContent[] _contents) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _contents | IAirdropERC20.AirdropContent[] | undefined |

### cancelPendingPayments

```solidity
function cancelPendingPayments(uint256 numberOfPaymentsToCancel) external nonpayable
```

Lets contract-owner cancel any pending payments.



#### Parameters

| Name | Type | Description |
|---|---|---|
| numberOfPaymentsToCancel | uint256 | undefined |

### getAllAirdropPayments

```solidity
function getAllAirdropPayments(uint256 startId, uint256 endId) external view returns (struct IAirdropERC20.AirdropContent[] contents)
```

Returns all airdrop payments set up -- pending, processed or failed.



#### Parameters

| Name | Type | Description |
|---|---|---|
| startId | uint256 | undefined |
| endId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| contents | IAirdropERC20.AirdropContent[] | undefined |

### getAllAirdropPaymentsFailed

```solidity
function getAllAirdropPaymentsFailed() external view returns (struct IAirdropERC20.AirdropContent[] contents)
```

Returns all pending airdrop failed.




#### Returns

| Name | Type | Description |
|---|---|---|
| contents | IAirdropERC20.AirdropContent[] | undefined |

### getAllAirdropPaymentsPending

```solidity
function getAllAirdropPaymentsPending(uint256 startId, uint256 endId) external view returns (struct IAirdropERC20.AirdropContent[] contents)
```

Returns all pending airdrop payments.



#### Parameters

| Name | Type | Description |
|---|---|---|
| startId | uint256 | undefined |
| endId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| contents | IAirdropERC20.AirdropContent[] | undefined |

### processPayments

```solidity
function processPayments(uint256 paymentsToProcess) external nonpayable
```

Lets contract-owner send ERC20 or native tokens to a list of addresses.

*The token-owner should approve target tokens to Airdrop contract,                   which acts as operator for the tokens.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| paymentsToProcess | uint256 | The number of airdrop payments to process. |



## Events

### AirdropPayment

```solidity
event AirdropPayment(address indexed recipient, uint256 index, bool failed)
```

Emitted when an airdrop payment is made to a recipient.



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipient `indexed` | address | undefined |
| index  | uint256 | undefined |
| failed  | bool | undefined |

### PaymentsCancelledByAdmin

```solidity
event PaymentsCancelledByAdmin(uint256 startIndex, uint256 endIndex)
```

Emitted when pending payments are cancelled, and processed count is reset.



#### Parameters

| Name | Type | Description |
|---|---|---|
| startIndex  | uint256 | undefined |
| endIndex  | uint256 | undefined |

### RecipientsAdded

```solidity
event RecipientsAdded(uint256 startIndex, uint256 endIndex)
```

Emitted when airdrop recipients are uploaded to the contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| startIndex  | uint256 | undefined |
| endIndex  | uint256 | undefined |

### StatelessAirdrop

```solidity
event StatelessAirdrop(address indexed recipient, IAirdropERC20.AirdropContent content, bool failed)
```

Emitted when an airdrop is made using the stateless airdrop function.



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipient `indexed` | address | undefined |
| content  | IAirdropERC20.AirdropContent | undefined |
| failed  | bool | undefined |



