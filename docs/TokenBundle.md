# TokenBundle



> Token Bundle

`TokenBundle` contract extension allows bundling-up of ERC20/ERC721/ERC1155 and native-tokan assets           in a data structure, and provides logic for setting/getting IDs and URIs for created bundles.

*See {ITokenBundle}*

## Methods

### getTokenCountOfBundle

```solidity
function getTokenCountOfBundle(uint256 _bundleId) external view returns (uint256)
```



*Returns the total number of assets in a particular bundle.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _bundleId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getTokenOfBundle

```solidity
function getTokenOfBundle(uint256 _bundleId, uint256 index) external view returns (struct ITokenBundle.Token)
```



*Returns an asset contained in a particular bundle, at a particular index.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _bundleId | uint256 | undefined |
| index | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | ITokenBundle.Token | undefined |

### getUriOfBundle

```solidity
function getUriOfBundle(uint256 _bundleId) external view returns (string)
```



*Returns the uri of a particular bundle.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _bundleId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |




