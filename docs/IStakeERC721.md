# IStakeERC721









## Methods

### calculateRewards

```solidity
function calculateRewards(address staker) external view
```

Calculated total rewards accumulated so far for a given staker.



#### Parameters

| Name | Type | Description |
|---|---|---|
| staker | address | Address for which to calculated rewards. |

### claimRewards

```solidity
function claimRewards() external nonpayable
```

Claim accumulated rewards.




### stake

```solidity
function stake(uint256[] tokenIds) external nonpayable
```

Stake ERC721 Tokens.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenIds | uint256[] | List of tokens to stake. |

### withdraw

```solidity
function withdraw(uint256[] tokenIds) external nonpayable
```

Withdraw staked tokens.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenIds | uint256[] | List of tokens to withdraw. |




