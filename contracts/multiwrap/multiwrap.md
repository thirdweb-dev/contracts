# Multiwrap design document.

This is a live document that explains what the [thirdweb](https://thirdweb.com/) `Multiwrap` smart contract is, how it works and can be used, and why it is written the way it is.

The document is written for technical and non-technical readers. To ask further questions about thirdweb’s `Multiwrap`, please join the [thirdweb discord](https://discord.gg/thirdweb) or create a github issue.

---

## Background

The thirdweb Multiwrap contract lets you wrap arbitrary ERC20, ERC721 and ERC1155 tokens you own into a single wrapped token / NFT.

The `Multiwrap` contract is meant to be used for bundling up multiple assets (ERC20 / ERC721 / ERC1155) into a single wrapped token, which can then
be unwrapped in exchange for the underlying tokens.

The single wrapped token received on bundling up multiple assets, as mentioned above, is an ERC721 NFT. It can be transferred, sold on any NFT Marketplace, and
generate royalties just like any other NFTs.

### Why we’re building `Multiwrap`

We're building `Multiwrap` for cases where an application wishes to bundle up / distribute / transact over *n* independent tokens all at once, as a single asset. This opens
up several novel NFT use cases.

For example, consider a lending service where people can take out a loan while putting up an NFT as a collateral. Using `Multiwrap`, a borrower can wrap their NFT with
some ether, and put up the resultant wrapped ERC721 NFT as collateral on the lending service. Now, the bowwoer's NFT, as collateral, has a floor value.

## Technical Details

The `Multiwrap` contract itself is an ERC721 contract. It lets you wrap arbitrary ERC20, ERC721 and ERC1155 tokens you own into a single wrapped token / NFT. This means
escrowing the relevant ERC20, ERC721 and ERC1155 tokens into the `Multiwrap` contract, and receiving the wrapped NFT in exchange. This wrapped NFT can later be 'unwrapped'
i.e. burned in exchange for the underlying tokens.

### Wrapping tokens

To wrap multiple ERC20, ERC721 or ERC1155 tokens as a single wrapped NFT, a token owner must first approve the relevant tokens to be transfered by the `Multiwrap` contract, and the token owner must then specify the tokens to wrapped into a single wrapped NFT. The following is the format in which each token to be wrapped must be specified:

```solidity
/// @notice The type of assets that can be wrapped.
enum TokenType { ERC20, ERC721, ERC1155 }

struct Token {
    address assetContract;
    TokenType tokenType;
    uint256 tokenId;
    uint256 amount;
}
```

| Parameters | Type | Description |
| --- | --- | --- |
| assetContract | address | The contract address of the asset to wrap. |
| tokenType | TokenType | The token type (ERC20 / ERC721 / ERC1155) of the asset to wrap. |
| tokenId | uint256 | The token Id of the asset to wrap, if the asset is an ERC721 / ERC1155 NFT. |
| amount | uint256 | The amount of the asset to wrap, if the asset is an ERC20 / ERC1155 fungible token. |

Each token in the bundle of tokens to be wrapped as a single wrapped NFT must be specified to the `Multiwrap` contract in the form of the `Token` struct. The contract handles the respective token based on the value of `tokenType` provided. Any incorrect values passed (e.g. the `amount` specified to be wrapped exceeds the token owner's token balance) will cause the wrapping transaction to revert.

Multiple tokens can be wrapped as a single wrapped NFT by calling the following function:

```solidity
function wrap(
    Token[] memory wrappedContents,
    string calldata uriForWrappedToken,
    address recipient
) external payable returns (uint256 tokenId);
```

| Parameters | Type | Description |
| --- | --- | --- |
| wrappedContents | Token[] | The tokens to wrap. |
| uriForWrappedToken | string | The metadata URI for the wrapped NFT. |
| recipient | address | The recipient of the wrapped NFT. |

When wrapping multiple assets into a single wrapped NFT, the assets are escrowed in the `Multiwrap` contract until the wrapped NFT is unwrapped.

### Unwrapping the wrapped NFT

The single wrapped NFT, received on wrapping multiple assets as explained in the previous section, can be unwrapped in exchange for the underlying assets. To unwrap a wrapped NFT, the wrapped NFT owner must specify the wrapped NFT's tokenId, and a recipient who shall receive the wrapped NFT's underlying assets.

```solidity
function unwrap(
    uint256 tokenId,
    address recipient
) external;
```

| Parameters | Type | Description |
| --- | --- | --- |
| tokenId | Token[] | The token Id of the wrapped NFT to unwrap.. |
| recipient | address | The recipient of the underlying ERC1155, ERC721, ERC20 tokens of the wrapped NFT. |

When unwrapping the single wrapped NFT, the wrapped NFT is burned.

### EIPs supported / implemented

The `Multiwrap` contract itself is an ERC721 contract i.e. it implements the [ERC721 standard](https://eips.ethereum.org/EIPS/eip-721). The contract also implements receiver interfaces for ERC721 and ERC1155 so it can receive, and thus, escrow ERC721 and ERC1155 tokens.

The contract also implements the [ERC2981](https://eips.ethereum.org/EIPS/eip-2981) royalty standard. That means the single wrapped token received on bundling up multiple assets can generate royalties just like any other NFTs.


## Limitations

Given the same interface for `wrap` and `unwrap`, the contract needs to be optimized for gas i.e. consume as much less gas as possible.

## Authors
- [nkrishang](https://github.com/nkrishang)
- [thirdweb team](https://github.com/thirdweb-dev)