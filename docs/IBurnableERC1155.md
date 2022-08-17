# IBurnableERC1155





`SignatureMint1155` is an ERC 1155 contract. It lets anyone mint NFTs by producing a mint request  and a signature (produced by an account with MINTER_ROLE, signing the mint request).



## Methods

### burn

```solidity
function burn(address account, uint256 id, uint256 value) external nonpayable
```



*Lets a token owner burn the tokens they own (i.e. destroy for good)*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| id | uint256 | undefined |
| value | uint256 | undefined |

### burnBatch

```solidity
function burnBatch(address account, uint256[] ids, uint256[] values) external nonpayable
```



*Lets a token owner burn multiple tokens they own at once (i.e. destroy for good)*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| ids | uint256[] | undefined |
| values | uint256[] | undefined |




