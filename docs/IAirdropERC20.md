# IAirdropERC20





Thirdweb&#39;s `Airdrop` contracts provide a lightweight and easy to use mechanism  to drop tokens.  `AirdropERC20` contract is an airdrop contract for ERC20 tokens. It follows a  push mechanism for transfer of tokens to intended recipients.



## Methods

### airdrop

```solidity
function airdrop(address tokenAddress, address tokenOwner, IAirdropERC20.AirdropContent[] contents) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenAddress | address | undefined |
| tokenOwner | address | undefined |
| contents | IAirdropERC20.AirdropContent[] | undefined |



## Events

### AirdropFailed

```solidity
event AirdropFailed(address indexed tokenAddress, address indexed tokenOwner, address indexed recipient, uint256 amount)
```

Emitted when an airdrop fails for a recipient address.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenAddress `indexed` | address | undefined |
| tokenOwner `indexed` | address | undefined |
| recipient `indexed` | address | undefined |
| amount  | uint256 | undefined |



