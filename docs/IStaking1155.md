# IStaking1155

*thirdweb*







## Methods

### claimRewards

```solidity
function claimRewards(uint256 tokenId) external nonpayable
```

Claim accumulated rewards.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | Staked token Id. |

### getStakeInfo

```solidity
function getStakeInfo(address staker) external view returns (uint256[] _tokensStaked, uint256[] _tokenAmounts, uint256 _totalRewards)
```

View amount staked and total rewards for a user.



#### Parameters

| Name | Type | Description |
|---|---|---|
| staker | address | Address for which to calculated rewards. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _tokensStaked | uint256[] | undefined |
| _tokenAmounts | uint256[] | undefined |
| _totalRewards | uint256 | undefined |

### getStakeInfoForToken

```solidity
function getStakeInfoForToken(uint256 tokenId, address staker) external view returns (uint256 _tokensStaked, uint256 _rewards)
```

View amount staked and total rewards for a user.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | Staked token Id. |
| staker | address | Address for which to calculated rewards. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _tokensStaked | uint256 | undefined |
| _rewards | uint256 | undefined |

### stake

```solidity
function stake(uint256 tokenId, uint256 amount) external nonpayable
```

Stake ERC721 Tokens.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | ERC1155 token-id to stake. |
| amount | uint256 | Amount to stake. |

### withdraw

```solidity
function withdraw(uint256 tokenId, uint256 amount) external nonpayable
```

Withdraw staked tokens.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | ERC1155 token-id to withdraw. |
| amount | uint256 | Amount to withdraw. |



## Events

### RewardsClaimed

```solidity
event RewardsClaimed(address indexed staker, uint256 rewardAmount)
```



*Emitted when a staker claims staking rewards.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| staker `indexed` | address | undefined |
| rewardAmount  | uint256 | undefined |

### TokensStaked

```solidity
event TokensStaked(address indexed staker, uint256 indexed tokenId, uint256 amount)
```



*Emitted when tokens are staked.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| staker `indexed` | address | undefined |
| tokenId `indexed` | uint256 | undefined |
| amount  | uint256 | undefined |

### TokensWithdrawn

```solidity
event TokensWithdrawn(address indexed staker, uint256 indexed tokenId, uint256 amount)
```



*Emitted when a set of staked token-ids are withdrawn.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| staker `indexed` | address | undefined |
| tokenId `indexed` | uint256 | undefined |
| amount  | uint256 | undefined |

### UpdatedDefaultRewardsPerUnitTime

```solidity
event UpdatedDefaultRewardsPerUnitTime(uint256 oldRewardsPerUnitTime, uint256 newRewardsPerUnitTime)
```



*Emitted when contract admin updates rewardsPerUnitTime.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| oldRewardsPerUnitTime  | uint256 | undefined |
| newRewardsPerUnitTime  | uint256 | undefined |

### UpdatedDefaultTimeUnit

```solidity
event UpdatedDefaultTimeUnit(uint256 oldTimeUnit, uint256 newTimeUnit)
```



*Emitted when contract admin updates timeUnit.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| oldTimeUnit  | uint256 | undefined |
| newTimeUnit  | uint256 | undefined |

### UpdatedRewardsPerUnitTime

```solidity
event UpdatedRewardsPerUnitTime(uint256 indexed _tokenId, uint256 oldRewardsPerUnitTime, uint256 newRewardsPerUnitTime)
```



*Emitted when contract admin updates rewardsPerUnitTime.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId `indexed` | uint256 | undefined |
| oldRewardsPerUnitTime  | uint256 | undefined |
| newRewardsPerUnitTime  | uint256 | undefined |

### UpdatedTimeUnit

```solidity
event UpdatedTimeUnit(uint256 indexed _tokenId, uint256 oldTimeUnit, uint256 newTimeUnit)
```



*Emitted when contract admin updates timeUnit.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId `indexed` | uint256 | undefined |
| oldTimeUnit  | uint256 | undefined |
| newTimeUnit  | uint256 | undefined |



