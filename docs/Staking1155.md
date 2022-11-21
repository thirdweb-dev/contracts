# Staking1155





note: This is a Beta release.



## Methods

### claimRewards

```solidity
function claimRewards(uint256 _tokenId) external nonpayable
```

Claim accumulated rewards.

*See {_claimRewards}. Override that to implement custom logic.             See {_calculateRewards} for reward-calculation logic.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | Staked token Id. |

### getStakeInfo

```solidity
function getStakeInfo(uint256 _tokenId, address _staker) external view returns (uint256 _tokensStaked, uint256 _rewards)
```

View amount staked and total rewards for a user.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined |
| _staker | address | Address for which to calculated rewards. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _tokensStaked | uint256 | undefined |
| _rewards | uint256 | undefined |

### nftCollection

```solidity
function nftCollection() external view returns (address)
```



*Address of ERC721 NFT contract -- staked tokens belong to this contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### rewardsPerUnitTime

```solidity
function rewardsPerUnitTime(uint256) external view returns (uint256)
```



*Rewards accumulated per unit of time.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### setRewardsPerUnitTime

```solidity
function setRewardsPerUnitTime(uint256 _tokenId, uint256 _rewardsPerUnitTime) external nonpayable
```

Set rewards per unit of time.           Interpreted as x rewards per second/per day/etc based on time-unit.

*Only admin/authorized-account can call it.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | ERC1155 token Id. |
| _rewardsPerUnitTime | uint256 | New rewards per unit time. |

### setTimeUnit

```solidity
function setTimeUnit(uint256 _tokenId, uint256 _timeUnit) external nonpayable
```

Set time unit. Set as a number of seconds.           Could be specified as -- x * 1 hours, x * 1 days, etc.

*Only admin/authorized-account can call it.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | ERC1155 token Id. |
| _timeUnit | uint256 | New time unit. |

### stake

```solidity
function stake(uint256 _tokenId, uint256 _amount) external nonpayable
```

Stake ERC721 Tokens.

*See {_stake}. Override that to implement custom logic.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | ERC1155 token-id to stake. |
| _amount | uint256 | Amount to stake. |

### stakers

```solidity
function stakers(uint256, address) external view returns (uint256 amountStaked, uint256 timeOfLastUpdate, uint256 unclaimedRewards)
```



*Mapping from staker address to Staker struct. See {struct IStaking.Staker}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| _1 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountStaked | uint256 | undefined |
| timeOfLastUpdate | uint256 | undefined |
| unclaimedRewards | uint256 | undefined |

### stakersArray

```solidity
function stakersArray(uint256, uint256) external view returns (address)
```



*List of accounts that have staked their NFTs.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| _1 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### timeUnit

```solidity
function timeUnit(uint256) external view returns (uint256)
```



*Unit of time specified in number of seconds. Can be set as 1 seconds, 1 days, 1 hours, etc.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### withdraw

```solidity
function withdraw(uint256 _tokenId, uint256 _amount) external nonpayable
```

Withdraw staked tokens.

*See {_withdraw}. Override that to implement custom logic.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | ERC1155 token-id to withdraw. |
| _amount | uint256 | Amount to withdraw. |



## Events

### RewardsClaimed

```solidity
event RewardsClaimed(address indexed staker, uint256 rewardAmount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| staker `indexed` | address | undefined |
| rewardAmount  | uint256 | undefined |

### TokensStaked

```solidity
event TokensStaked(address indexed staker, uint256 indexed tokenId, uint256 amount)
```





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





#### Parameters

| Name | Type | Description |
|---|---|---|
| staker `indexed` | address | undefined |
| tokenId `indexed` | uint256 | undefined |
| amount  | uint256 | undefined |

### UpdatedRewardsPerUnitTime

```solidity
event UpdatedRewardsPerUnitTime(uint256 _tokenId, uint256 oldRewardsPerUnitTime, uint256 newRewardsPerUnitTime)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId  | uint256 | undefined |
| oldRewardsPerUnitTime  | uint256 | undefined |
| newRewardsPerUnitTime  | uint256 | undefined |

### UpdatedTimeUnit

```solidity
event UpdatedTimeUnit(uint256 _tokenId, uint256 oldTimeUnit, uint256 newTimeUnit)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId  | uint256 | undefined |
| oldTimeUnit  | uint256 | undefined |
| newTimeUnit  | uint256 | undefined |



