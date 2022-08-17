# IMintableERC1155





`SignatureMint1155` is an ERC 1155 contract. It lets anyone mint NFTs by producing a mint request  and a signature (produced by an account with MINTER_ROLE, signing the mint request).



## Methods

### mintTo

```solidity
function mintTo(address to, uint256 tokenId, string uri, uint256 amount) external nonpayable
```

Lets an account with MINTER_ROLE mint an NFT.



#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | The address to mint the NFT to. |
| tokenId | uint256 | The tokenId of the NFTs to mint |
| uri | string | The URI to assign to the NFT. |
| amount | uint256 | The number of copies of the NFT to mint. |



## Events

### TokensMinted

```solidity
event TokensMinted(address indexed mintedTo, uint256 indexed tokenIdMinted, string uri, uint256 quantityMinted)
```



*Emitted when an account with MINTER_ROLE mints an NFT.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| mintedTo `indexed` | address | undefined |
| tokenIdMinted `indexed` | uint256 | undefined |
| uri  | string | undefined |
| quantityMinted  | uint256 | undefined |



