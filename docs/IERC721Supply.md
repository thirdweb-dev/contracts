# IERC721Supply



> ERC-721 Non-Fungible Token Standard, optional supplu extension



*See https://eips.ethereum.org/EIPS/eip-721  Note: the ERC-165 identifier for this interface is 0x780e9d63.*

## Methods

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```

Count NFTs tracked by this contract




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | A count of valid NFTs tracked by this contract, where each one of  them has an assigned and queryable owner not equal to the zero address |




