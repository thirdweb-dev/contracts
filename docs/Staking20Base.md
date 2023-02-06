# Staking20Base





note: This contract is provided as a base contract.



## Methods

### claimRewards

```solidity
function claimRewards() external nonpayable
```

Claim accumulated rewards.

*See {_claimRewards}. Override that to implement custom logic.             See {_calculateRewards} for reward-calculation logic.*


### contractURI

```solidity
function contractURI() external view returns (string)
```

Returns the contract metadata URI.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### depositRewardTokens

```solidity
function depositRewardTokens(uint256 _amount) external payable
```



*Admin deposits reward tokens.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | undefined |

### getRewardRatio

```solidity
function getRewardRatio() external view returns (uint256 _numerator, uint256 _denominator)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _numerator | uint256 | undefined |
| _denominator | uint256 | undefined |

### getRewardTokenBalance

```solidity
function getRewardTokenBalance() external view returns (uint256)
```

View total rewards available in the staking contract.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getStakeInfo

```solidity
function getStakeInfo(address _staker) external view returns (uint256 _tokensStaked, uint256 _rewards)
```

View amount staked and rewards for a user.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _staker | address | Address for which to calculated rewards. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _tokensStaked | uint256 |   Amount of tokens staked. |
| _rewards | uint256 |        Available reward amount. |

### getTimeUnit

```solidity
function getTimeUnit() external view returns (uint256 _timeUnit)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _timeUnit | uint256 | undefined |

### multicall

```solidity
function multicall(bytes[] data) external nonpayable returns (bytes[] results)
```

Receives and executes a batch of function calls on this contract.

*Receives and executes a batch of function calls on this contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes[] | The bytes data that makes up the batch of function calls to execute. |

#### Returns

| Name | Type | Description |
|---|---|---|
| results | bytes[] | The bytes data that makes up the result of the batch of function calls executed. |

### owner

```solidity
function owner() external view returns (address)
```

Returns the owner of the contract.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### rewardToken

```solidity
function rewardToken() external view returns (address)
```



*ERC20 Reward Token address. See {_mintRewards} below.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### rewardTokenDecimals

```solidity
function rewardTokenDecimals() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### setContractURI

```solidity
function setContractURI(string _uri) external nonpayable
```

Lets a contract admin set the URI for contract-level metadata.

*Caller should be authorized to setup contractURI, e.g. contract admin.                  See {_canSetContractURI}.                  Emits {ContractURIUpdated Event}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _uri | string | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |

### setOwner

```solidity
function setOwner(address _newOwner) external nonpayable
```

Lets an authorized wallet set a new owner for the contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _newOwner | address | The address to set as the new owner of the contract. |

### setRewardRatio

```solidity
function setRewardRatio(uint256 _numerator, uint256 _denominator) external nonpayable
```

Set rewards per unit of time.           Interpreted as (numerator/denominator) rewards per second/per day/etc based on time-unit.           For e.g., ratio of 1/20 would mean 1 reward token for every 20 tokens staked.

*Only admin/authorized-account can call it.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _numerator | uint256 | Reward ratio numerator. |
| _denominator | uint256 | Reward ratio denominator. |

### setTimeUnit

```solidity
function setTimeUnit(uint256 _timeUnit) external nonpayable
```

Set time unit. Set as a number of seconds.           Could be specified as -- x * 1 hours, x * 1 days, etc.

*Only admin/authorized-account can call it.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _timeUnit | uint256 | New time unit. |

### stake

```solidity
function stake(uint256 _amount) external payable
```

Stake ERC20 Tokens.

*See {_stake}. Override that to implement custom logic.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | Amount to stake. |

### stakers

```solidity
function stakers(address) external view returns (uint256 amountStaked, uint256 timeOfLastUpdate, uint256 unclaimedRewards, uint256 conditionIdOflastUpdate)
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
| conditionIdOflastUpdate | uint256 | undefined |

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

### stakingToken

```solidity
function stakingToken() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### stakingTokenBalance

```solidity
function stakingTokenBalance() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### stakingTokenDecimals

```solidity
function stakingTokenDecimals() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### withdraw

```solidity
function withdraw(uint256 _amount) external nonpayable
```

Withdraw staked ERC20 tokens.

*See {_withdraw}. Override that to implement custom logic.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | Amount to withdraw. |

### withdrawRewardTokens

```solidity
function withdrawRewardTokens(uint256 _amount) external nonpayable
```



*Admin can withdraw excess reward tokens.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | undefined |



## Events

### ContractURIUpdated

```solidity
event ContractURIUpdated(string prevURI, string newURI)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prevURI  | string | undefined |
| newURI  | string | undefined |

### OwnerUpdated

```solidity
event OwnerUpdated(address indexed prevOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prevOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

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
event TokensStaked(address indexed staker, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| staker `indexed` | address | undefined |
| amount  | uint256 | undefined |

### TokensWithdrawn

```solidity
event TokensWithdrawn(address indexed staker, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| staker `indexed` | address | undefined |
| amount  | uint256 | undefined |

### UpdatedMinStakeAmount

```solidity
event UpdatedMinStakeAmount(uint256 oldAmount, uint256 newAmount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| oldAmount  | uint256 | undefined |
| newAmount  | uint256 | undefined |

### UpdatedRewardRatio

```solidity
event UpdatedRewardRatio(uint256 oldNumerator, uint256 newNumerator, uint256 oldDenominator, uint256 newDenominator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| oldNumerator  | uint256 | undefined |
| newNumerator  | uint256 | undefined |
| oldDenominator  | uint256 | undefined |
| newDenominator  | uint256 | undefined |

### UpdatedTimeUnit

```solidity
event UpdatedTimeUnit(uint256 oldTimeUnit, uint256 newTimeUnit)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| oldTimeUnit  | uint256 | undefined |
| newTimeUnit  | uint256 | undefined |



