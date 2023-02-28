# IMintableERC20

*thirdweb*







## Methods

### mintTo

```solidity
function mintTo(address to, uint256 amount) external nonpayable
```



*Creates `amount` new tokens for `to`. See {ERC20-_mint}. Requirements: - the caller must have the `MINTER_ROLE`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | undefined |
| amount | uint256 | undefined |



## Events

### TokensMinted

```solidity
event TokensMinted(address indexed mintedTo, uint256 quantityMinted)
```



*Emitted when tokens are minted with `mintTo`*

#### Parameters

| Name | Type | Description |
|---|---|---|
| mintedTo `indexed` | address | undefined |
| quantityMinted  | uint256 | undefined |



