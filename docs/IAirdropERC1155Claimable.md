# IAirdropERC1155Claimable





Thirdweb&#39;s `Airdrop` contracts provide a lightweight and easy to use mechanism  to drop tokens.  `AirdropERC1155Claimable` contract is an airdrop contract for ERC1155 tokens. It follows a  pull mechanism for transfer of tokens, where allowlisted recipients can claim tokens from  the contract.



## Methods

### claim

```solidity
function claim(address receiver, uint256 quantity, uint256 tokenId, bytes32[] proofs, uint256 proofMaxQuantityForWallet) external nonpayable
```

Lets an account claim a given quantity of ERC1155 tokens.



#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | The receiver of the tokens to claim. |
| quantity | uint256 | The quantity of tokens to claim. |
| tokenId | uint256 | Token Id to claim. |
| proofs | bytes32[] | The proof of the claimer&#39;s inclusion in the merkle root allowlist                                        of the claim conditions that apply. |
| proofMaxQuantityForWallet | uint256 | The maximum number of tokens an address included in an                                        allowlist can claim. |



## Events

### TokensClaimed

```solidity
event TokensClaimed(address indexed claimer, address indexed receiver, uint256 indexed tokenId, uint256 quantityClaimed)
```



*Emitted when tokens are claimed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId `indexed` | uint256 | undefined |
| quantityClaimed  | uint256 | undefined |



