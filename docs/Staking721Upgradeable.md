# Staking721Upgradeable









## Methods

### claimRewards

```solidity
function claimRewards() external nonpayable
```

Claim accumulated rewards.




### getStakeInfo

```solidity
function getStakeInfo(address _staker) external view returns (uint256 _tokensStaked, uint256 _rewards)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _staker | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _tokensStaked | uint256 | undefined |
| _rewards | uint256 | undefined |

### nftCollection

```solidity
function nftCollection() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### rewardsPerUnitTime

```solidity
function rewardsPerUnitTime() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### setRewardsPerUnitTime

```solidity
function setRewardsPerUnitTime(uint256 _rewardsPerUnitTime) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _rewardsPerUnitTime | uint256 | undefined |

### setTimeUnit

```solidity
function setTimeUnit(uint256 _timeUnit) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _timeUnit | uint256 | undefined |

### stake

```solidity
function stake(uint256[] _tokenIds) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenIds | uint256[] | undefined |

### stakerAddress

```solidity
function stakerAddress(uint256) external view returns (address)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### stakers

```solidity
function stakers(address) external view returns (uint256 amountStaked, uint256 timeOfLastUpdate, uint256 unclaimedRewards)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amountStaked | uint256 | undefined |
| timeOfLastUpdate | uint256 | undefined |
| unclaimedRewards | uint256 | undefined |

### stakersArray

```solidity
function stakersArray(uint256) external view returns (address)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### timeUnit

```solidity
function timeUnit() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### withdraw

```solidity
function withdraw(uint256[] _tokenIds) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenIds | uint256[] | undefined |



## Events

### Initialized

```solidity
event Initialized(uint8 version)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |



