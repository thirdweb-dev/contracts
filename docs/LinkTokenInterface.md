# LinkTokenInterface









## Methods

### allowance

```solidity
function allowance(address owner, address spender) external view returns (uint256 remaining)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined
| spender | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| remaining | uint256 | undefined

### approve

```solidity
function approve(address spender, uint256 value) external nonpayable returns (bool success)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined
| value | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined

### balanceOf

```solidity
function balanceOf(address owner) external view returns (uint256 balance)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| balance | uint256 | undefined

### decimals

```solidity
function decimals() external view returns (uint8 decimalPlaces)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| decimalPlaces | uint8 | undefined

### decreaseApproval

```solidity
function decreaseApproval(address spender, uint256 addedValue) external nonpayable returns (bool success)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined
| addedValue | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined

### increaseApproval

```solidity
function increaseApproval(address spender, uint256 subtractedValue) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined
| subtractedValue | uint256 | undefined

### name

```solidity
function name() external view returns (string tokenName)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| tokenName | string | undefined

### symbol

```solidity
function symbol() external view returns (string tokenSymbol)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| tokenSymbol | string | undefined

### totalSupply

```solidity
function totalSupply() external view returns (uint256 totalTokensIssued)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| totalTokensIssued | uint256 | undefined

### transfer

```solidity
function transfer(address to, uint256 value) external nonpayable returns (bool success)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | undefined
| value | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined

### transferAndCall

```solidity
function transferAndCall(address to, uint256 value, bytes data) external nonpayable returns (bool success)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | undefined
| value | uint256 | undefined
| data | bytes | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 value) external nonpayable returns (bool success)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined
| to | address | undefined
| value | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined




