# ILoyaltyCard









## Methods

### cancel

```solidity
function cancel(uint256 tokenId) external nonpayable
```

Let&#39;s a loyalty card owner or approved operator cancel the loyalty card.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |

### mintTo

```solidity
function mintTo(address to, string uri) external nonpayable returns (uint256)
```

Lets an account with MINTER_ROLE mint an NFT.



#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | The address to mint the NFT to. |
| uri | string | The URI to assign to the NFT. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | tokenId of the NFT minted. |

### revoke

```solidity
function revoke(uint256 tokenId) external nonpayable
```

Let&#39;s an approved party cancel the loyalty card (no approval needed).



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |



## Events

### TokensMinted

```solidity
event TokensMinted(address indexed mintedTo, uint256 indexed tokenIdMinted, string uri)
```



*Emitted when an account with MINTER_ROLE mints an NFT.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| mintedTo `indexed` | address | undefined |
| tokenIdMinted `indexed` | uint256 | undefined |
| uri  | string | undefined |



