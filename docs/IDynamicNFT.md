# IDynamicNFT









## Methods

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

### mintWithSignature

```solidity
function mintWithSignature(ISignatureMintERC721.MintRequest req, bytes signature) external payable returns (address signer)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| req | ISignatureMintERC721.MintRequest | undefined |
| signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |

### setTokenURI

```solidity
function setTokenURI(uint256 _tokenId, string _uri) external nonpayable
```

Sets the metadata URI for a given NFT.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined |
| _uri | string | undefined |

### verify

```solidity
function verify(ISignatureMintERC721.MintRequest req, bytes signature) external view returns (bool success, address signer)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| req | ISignatureMintERC721.MintRequest | undefined |
| signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined |
| signer | address | undefined |



## Events

### TokenURIUpdated

```solidity
event TokenURIUpdated(uint256 indexed tokenId, string prevURI, string newURI)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId `indexed` | uint256 | undefined |
| prevURI  | string | undefined |
| newURI  | string | undefined |

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

### TokensMintedWithSignature

```solidity
event TokensMintedWithSignature(address indexed signer, address indexed mintedTo, uint256 indexed tokenIdMinted, ISignatureMintERC721.MintRequest mintRequest)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| signer `indexed` | address | undefined |
| mintedTo `indexed` | address | undefined |
| tokenIdMinted `indexed` | uint256 | undefined |
| mintRequest  | ISignatureMintERC721.MintRequest | undefined |



