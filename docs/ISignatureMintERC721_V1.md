# ISignatureMintERC721_V1









## Methods

### mintWithSignature

```solidity
function mintWithSignature(ITokenERC721.MintRequest _req, bytes _signature) external payable returns (uint256 tokenIdMinted)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _req | ITokenERC721.MintRequest | undefined |
| _signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| tokenIdMinted | uint256 | undefined |

### verify

```solidity
function verify(ITokenERC721.MintRequest _req, bytes _signature) external view returns (bool, address)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _req | ITokenERC721.MintRequest | undefined |
| _signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |
| _1 | address | undefined |




