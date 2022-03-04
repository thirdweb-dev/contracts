# PaymentSplitterUpgradeable



> PaymentSplitter



*This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware that the Ether will be split in this way, since it is handled transparently by the contract. The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim an amount proportional to the percentage of total shares they were assigned. `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release} function. NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you to run tests before sending real value to this contract.*

## Methods

### payee

```solidity
function payee(uint256 index) external view returns (address)
```



*Getter for the address of the payee number `index`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| index | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

### payeeCount

```solidity
function payeeCount() external view returns (uint256)
```



*Get the number of payees*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### release

```solidity
function release(contract IERC20Upgradeable token, address account) external nonpayable
```



*Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20 contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| token | contract IERC20Upgradeable | undefined
| account | address | undefined

### released

```solidity
function released(address account) external view returns (uint256)
```



*Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an IERC20 contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### shares

```solidity
function shares(address account) external view returns (uint256)
```



*Getter for the amount of shares held by an account.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### totalReleased

```solidity
function totalReleased() external view returns (uint256)
```



*Getter for the total amount of `token` already released. `token` should be the address of an IERC20 contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### totalShares

```solidity
function totalShares() external view returns (uint256)
```



*Getter for the total shares held by payees.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined



## Events

### ERC20PaymentReleased

```solidity
event ERC20PaymentReleased(contract IERC20Upgradeable indexed token, address to, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| token `indexed` | contract IERC20Upgradeable | undefined |
| to  | address | undefined |
| amount  | uint256 | undefined |

### PayeeAdded

```solidity
event PayeeAdded(address account, uint256 shares)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account  | address | undefined |
| shares  | uint256 | undefined |

### PaymentReceived

```solidity
event PaymentReceived(address from, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from  | address | undefined |
| amount  | uint256 | undefined |

### PaymentReleased

```solidity
event PaymentReleased(address to, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| to  | address | undefined |
| amount  | uint256 | undefined |



