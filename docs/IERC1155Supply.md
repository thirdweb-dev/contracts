# IERC1155Supply



> ERC1155S Non-Fungible Token Standard, optional supply extension



*See https://eips.ethereum.org/EIPS/eip-1155*

## Methods

### totalSupply

```solidity
function totalSupply(uint256 id) external view returns (uint256)
```

Count NFTs tracked by this contract



#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | A count of valid NFTs tracked by this contract, where each one of  them has an assigned and queryable owner not equal to the zero address |




