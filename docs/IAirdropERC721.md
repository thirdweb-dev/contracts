# IAirdropERC721





Thirdweb&#39;s `Airdrop` contracts provide a lightweight and easy to use mechanism  to drop tokens.  `AirdropERC721` contract is an airdrop contract for ERC721 tokens. It follows a  push mechanism for transfer of tokens to intended recipients.



## Methods

### airdrop

```solidity
function airdrop(address tokenAddress, address tokenOwner, IAirdropERC721.AirdropContent[] contents) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenAddress | address | undefined |
| tokenOwner | address | undefined |
| contents | IAirdropERC721.AirdropContent[] | undefined |



## Events

### AirdropFailed

```solidity
event AirdropFailed(address indexed tokenAddress, address indexed tokenOwner, address indexed recipient, uint256 tokenId)
```

Emitted when an airdrop fails for a recipient address.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenAddress `indexed` | address | undefined |
| tokenOwner `indexed` | address | undefined |
| recipient `indexed` | address | undefined |
| tokenId  | uint256 | undefined |



