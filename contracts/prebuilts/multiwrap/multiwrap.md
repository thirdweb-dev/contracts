# Multiwrap design document.

This is a live document that explains what the [thirdweb](https://thirdweb.com/) `Multiwrap` smart contract is, how it works and can be used, and why it is designed the way it is.

The document is written for technical and non-technical readers. To ask further questions about thirdweb’s `Multiwrap` contract, please join the [thirdweb discord](https://discord.gg/thirdweb) or create a github issue.

---

## Background

The thirdweb Multiwrap contract lets you wrap arbitrary ERC20, ERC721 and ERC1155 tokens you own into a single wrapped token / NFT.

The `Multiwrap` contract is meant to be used for bundling up multiple assets (ERC20 / ERC721 / ERC1155) into a single wrapped token, which can then be unwrapped in exchange for the underlying tokens.

The single wrapped token received on bundling up multiple assets, as mentioned above, is an ERC721 NFT. It can be transferred, sold on any NFT Marketplace, and generate royalties just like any other NFTs.

### How the `Multiwrap` product *should* work

![multiwrap-diagram.png](/assets/multiwrap-diagram.png)

A token owner should be able to wrap any combination of *n* ERC20, ERC721 or ERC1155 tokens as a wrapped NFT. When wrapping, the token owner should be able to specify a recipient for the wrapped NFT. At the time of wrapping, the token owner should be able to set the metadata of the wrapped NFT that will be minted.

The wrapped NFT owner should be able to unwrap the NFT to retrieve the underlying tokens of the wrapped NFT. At the time of unwrapping, the wrapped NFT owner should be able to specify a recipient for the underlying tokens of the wrapped NFT.

The `Multiwrap` contract creator should be able to apply the following role-based restrictions:

- Restrict what assets can be wrapped on the contract.
- Restrict which wallets can wrap tokens on the contract.
- Restrict what wallets can unwrap owned wrapped NFTs.

### Core parts of the `Multiwrap` product
- A token owner should be able to wrap any combination of *n* ERC20, ERC721 or ERC1155 tokens as a wrapped token.
- A wrapped token owner should be able to unwrap the token to retrieve the underlying contents of the wrapped token.

### Why we’re building `Multiwrap`

We're building `Multiwrap` for cases where an application wishes to bundle up / distribute / transact over *n* independent tokens all at once, as a single asset. This opens up several novel NFT use cases.

For example, consider a lending service where people can take out a loan while putting up an NFT as a collateral. Using `Multiwrap`, a borrower can wrap their NFT with some ether, and put up the resultant wrapped ERC721 NFT as collateral on the lending service. Now, the borrower's NFT, as collateral, has a floor value.

## Technical Details

The `Multiwrap`contract itself is an ERC721 contract. 

It lets you wrap arbitrary ERC20, ERC721 or ERC1155 tokens you own into a single wrapped token / NFT. This means escrowing the relevant ERC20, ERC721 and ERC1155 tokens into the `Multiwrap` contract, and receiving the wrapped NFT in exchange. 

This wrapped NFT can later be 'unwrapped' i.e. burned in exchange for the underlying tokens.

### Wrapping tokens

To wrap multiple ERC20, ERC721 or ERC1155 tokens as a single wrapped NFT, a token owner must:
- approve the relevant tokens to be transferred by the `Multiwrap` contract.
- specify the tokens to be wrapped into a single wrapped NFT. The following is the format in which each token to be wrapped must be specified:

```solidity
/// @notice The type of assets that can be wrapped.
enum TokenType { ERC20, ERC721, ERC1155 }

struct Token {
    address assetContract;
    TokenType tokenType;
    uint256 tokenId;
    uint256 totalAmount;
}
```

| Parameters | Type | Description |
| --- | --- | --- |
| assetContract | address | The contract address of the asset to wrap. |
| tokenType | TokenType | The token type (ERC20 / ERC721 / ERC1155) of the asset to wrap. |
| tokenId | uint256 | The token Id of the asset to wrap, if the asset is an ERC721 / ERC1155 NFT. |
| totalAmount | uint256 | The amount of the asset to wrap, if the asset is an ERC20 / ERC1155 fungible token. |

Each token in the bundle of tokens to be wrapped as a single wrapped NFT must be specified to the `Multiwrap` contract in the form of the `Token` struct. The contract handles the respective token based on the value of `tokenType` provided. Any incorrect values passed (e.g. the `totalAmount` specified to be wrapped exceeds the token owner's token balance) will cause the wrapping transaction to revert.

Multiple tokens can be wrapped as a single wrapped NFT by calling the following function:

```solidity
function wrap(
    Token[] memory tokensToWrap,
    string calldata uriForWrappedToken,
    address recipient
) external payable returns (uint256 tokenId);
```

| Parameters | Type | Description |
| --- | --- | --- |
| tokensToWrap | Token[] | The tokens to wrap. |
| uriForWrappedToken | string | The metadata URI for the wrapped NFT. |
| recipient | address | The recipient of the wrapped NFT. |

### Unwrapping the wrapped NFT

The single wrapped NFT, received on wrapping multiple assets as explained in the previous section, can be unwrapped in exchange for the underlying assets. 

A wrapped NFT can be unwrapped either by the owner, or a wallet approved by the owner to transfer the NFT via `setApprovalForAll` or `approve` ERC721 functions.

When unwrapping the wrapped NFT, the wrapped NFT is burned.****

A wrapped NFT can be unwrapped by calling the following function:

```solidity
function unwrap(
    uint256 tokenId,
    address recipient
) external;
```

| Parameters | Type | Description |
| --- | --- | --- |
| tokenId | Token[] | The token Id of the wrapped NFT to unwrap. |
| recipient | address | The recipient of the underlying ERC20, ERC721 or ERC1155 tokens of the wrapped NFT. |

## Permissions

| Role name | Type (Switch / !Switch) | Purpose |
| -- | -- | -- |
| TRANSFER_ROLE | Switch | Only token transfers to or from role holders are allowed. |
| MINTER_ROLE | Switch | Only role holders can wrap tokens. |
| UNWRAP_ROLE | Switch | Only role holders can unwrap wrapped NFTs. |
| ASSET_ROLE | Switch | Only assets with the role can be wrapped. |

What does **Type (Switch / !Switch)** mean?
- **Switch:** If `address(0)` has `ROLE`, then the `ROLE` restrictions don't apply.
- **!Switch:** `ROLE` restrictions always apply.

## Relevant EIPs

| EIP | Link | Relation to `Multiwrap` |
| -- | -- | -- |
| 721 | https://eips.ethereum.org/EIPS/eip-721 | Multiwrap itself is an ERC721 contract. The wrapped NFT received by a token owner on wrapping is an ERC721 NFT. Additionally, ERC721 tokens can be wrapped. |
| 20 | https://eips.ethereum.org/EIPS/eip-20 | ERC20 tokens can be wrapped. |
| 1155 | https://eips.ethereum.org/EIPS/eip-1155 | ERC1155 tokens can be wrapped. |
| 2981 | https://eips.ethereum.org/EIPS/eip-2981 | Multiwrap implements ERC 2981 for distributing royalties for sales of the wrapped NFTs. |
| 2771 | https://eips.ethereum.org/EIPS/eip-2771 | Multiwrap implements ERC 2771 to support meta-transactions (aka “gasless” transactions). |

## Authors
- [nkrishang](https://github.com/nkrishang)
- [thirdweb team](https://github.com/thirdweb-dev)
