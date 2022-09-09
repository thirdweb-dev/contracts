# IAirdropERC20Claimable





Thirdweb&#39;s &#39;Airdrop&#39; contracts provide a lightweight and easy to use mechanism  to drop tokens.  `AirdropERC721` contract is an airdrop contract for ERC721 tokens.



## Methods

### claim

```solidity
function claim(address receiver, uint256 quantity, bytes32[] proofs, uint256 proofMaxQuantityForWallet) external nonpayable
```

Lets an account claim a given quantity of NFTs.



#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | The receiver of the NFTs to claim. |
| quantity | uint256 | The quantity of NFTs to claim. |
| proofs | bytes32[] | The proof of the claimer&#39;s inclusion in the merkle root allowlist                                        of the claim conditions that apply. |
| proofMaxQuantityForWallet | uint256 | The maximum number of NFTs an address included in an                                        allowlist can claim. |



## Events

### TokensClaimed

```solidity
event TokensClaimed(address indexed claimer, address indexed receiver, uint256 quantityClaimed)
```



*Emitted when tokens are claimed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| quantityClaimed  | uint256 | undefined |



