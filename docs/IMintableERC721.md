# IMintableERC721

*thirdweb*







## Methods

### mintTo

```solidity
function mintTo(address to, string uri) external nonpayable returns (uint256)
```

Lets an account mint an NFT.



#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | The address to mint the NFT to. |
| uri | string | The URI to assign to the NFT. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | tokenId of the NFT minted. |



## Events

### TokensMinted

```solidity
event TokensMinted(address indexed mintedTo, uint256 indexed tokenIdMinted, string uri)
```



*Emitted when tokens are minted via `mintTo`*

#### Parameters

| Name | Type | Description |
|---|---|---|
| mintedTo `indexed` | address | undefined |
| tokenIdMinted `indexed` | uint256 | undefined |
| uri  | string | undefined |



