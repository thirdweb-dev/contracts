# IERC721Metadata



> ERC-721 Non-Fungible Token Standard, optional metadata extension



*See https://eips.ethereum.org/EIPS/eip-721  Note: the ERC-165 identifier for this interface is 0x5b5e139f.*

## Methods

### name

```solidity
function name() external view returns (string)
```

A descriptive name for a collection of NFTs in this contract




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### symbol

```solidity
function symbol() external view returns (string)
```

An abbreviated name for NFTs in this contract




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### tokenURI

```solidity
function tokenURI(uint256 _tokenId) external view returns (string)
```

A distinct Uniform Resource Identifier (URI) for a given asset.

*Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC  3986. The URI may point to a JSON file that conforms to the &quot;ERC721  Metadata JSON Schema&quot;.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |




