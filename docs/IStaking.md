# IStaking









## Methods

### claimRewards

```solidity
function claimRewards() external nonpayable
```

Claim accumulated rewards.




### getStakeInfo

```solidity
function getStakeInfo(address staker) external view returns (uint256 _tokensStaked, uint256 _rewards)
```

View amount staked and total rewards for a user.



#### Parameters

| Name | Type | Description |
|---|---|---|
| staker | address | Address for which to calculated rewards. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _tokensStaked | uint256 | undefined |
| _rewards | uint256 | undefined |

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




