# ITokenStake





Thirdweb&#39;s TokenStake smart contract allows users to stake their ERC-20 Tokens  and earn rewards in form of a different ERC-20 token.  note:  - Reward token and staking token can&#39;t be changed after deployment.    Reward token contract can&#39;t be same as the staking token contract.  - ERC20 tokens from only the specified contract can be staked.  - All token transfers require approval on their respective token-contracts.  - Admin must deposit reward tokens using the `depositRewardTokens` function only.    Any direct transfers may cause unintended consequences, such as locking of tokens.  - Users must stake tokens using the `stake` function only.    Any direct transfers may cause unintended consequences, such as locking of tokens.



## Methods

### depositRewardTokens

```solidity
function depositRewardTokens(uint256 _amount) external payable
```

Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) deposit reward-tokens.          note: Tokens should be approved on the reward-token contract before depositing.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | Amount of tokens to deposit. |

### withdrawRewardTokens

```solidity
function withdrawRewardTokens(uint256 _amount) external nonpayable
```

Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) withdraw reward-tokens.          Useful for removing excess balance, thus preventing locking of tokens.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | Amount of tokens to deposit. |



## Events

### RewardTokensDepositedByAdmin

```solidity
event RewardTokensDepositedByAdmin(uint256 _amount)
```



*Emitted when contract admin deposits reward tokens.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount  | uint256 | undefined |

### RewardTokensWithdrawnByAdmin

```solidity
event RewardTokensWithdrawnByAdmin(uint256 _amount)
```



*Emitted when contract admin withdraws reward tokens.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount  | uint256 | undefined |



