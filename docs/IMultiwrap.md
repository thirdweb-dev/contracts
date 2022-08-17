# IMultiwrap





Thirdweb&#39;s Multiwrap contract lets you wrap arbitrary ERC20, ERC721 and ERC1155  tokens you own into a single wrapped token / NFT.  A wrapped NFT can be unwrapped i.e. burned in exchange for its underlying contents.



## Methods

### unwrap

```solidity
function unwrap(uint256 tokenId, address recipient) external nonpayable
```

Unwrap a wrapped NFT to retrieve underlying ERC1155, ERC721, ERC20 tokens.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | The token Id of the wrapped NFT to unwrap. |
| recipient | address | The recipient of the underlying ERC1155, ERC721, ERC20 tokens of the wrapped NFT. |

### wrap

```solidity
function wrap(ITokenBundle.Token[] wrappedContents, string uriForWrappedToken, address recipient) external payable returns (uint256 tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| wrappedContents | ITokenBundle.Token[] | undefined |
| uriForWrappedToken | string | undefined |
| recipient | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |



## Events

### TokensUnwrapped

```solidity
event TokensUnwrapped(address indexed unwrapper, address indexed recipientOfWrappedContents, uint256 indexed tokenIdOfWrappedToken)
```



*Emitted when tokens are unwrapped.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| unwrapper `indexed` | address | undefined |
| recipientOfWrappedContents `indexed` | address | undefined |
| tokenIdOfWrappedToken `indexed` | uint256 | undefined |

### TokensWrapped

```solidity
event TokensWrapped(address indexed wrapper, address indexed recipientOfWrappedToken, uint256 indexed tokenIdOfWrappedToken, ITokenBundle.Token[] wrappedContents)
```



*Emitted when tokens are wrapped.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| wrapper `indexed` | address | undefined |
| recipientOfWrappedToken `indexed` | address | undefined |
| tokenIdOfWrappedToken `indexed` | uint256 | undefined |
| wrappedContents  | ITokenBundle.Token[] | undefined |



