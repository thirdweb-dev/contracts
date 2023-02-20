# TokenStake









## Methods

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### claimRewards

```solidity
function claimRewards() external nonpayable
```

Claim accumulated rewards.

*See {_claimRewards}. Override that to implement custom logic.             See {_calculateRewards} for reward-calculation logic.*


### contractType

```solidity
function contractType() external pure returns (bytes32)
```



*Returns the module type of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### contractURI

```solidity
function contractURI() external view returns (string)
```

Returns the contract metadata URI.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### contractVersion

```solidity
function contractVersion() external pure returns (uint8)
```



*Returns the version of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint8 | undefined |

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

### getRoleAdmin

```solidity
function getRoleAdmin(bytes32 role) external view returns (bytes32)
```

Returns the admin role that controls the specified role.

*See {grantRole} and {revokeRole}.                  To change a role&#39;s admin, use {_setRoleAdmin}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### getRoleMember

```solidity
function getRoleMember(bytes32 role, uint256 index) external view returns (address member)
```

Returns the role-member from a list of members for a role,                  at a given index.

*Returns `member` who has `role`, at `index` of role-members list.                  See struct {RoleMembers}, and mapping {roleMembers}*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |
| index | uint256 | Index in list of current members for the role. |

#### Returns

| Name | Type | Description |
|---|---|---|
| member | address |  Address of account that has `role` |

### getRoleMemberCount

```solidity
function getRoleMemberCount(bytes32 role) external view returns (uint256 count)
```

Returns total number of accounts that have a role.

*Returns `count` of accounts that have `role`.                  See struct {RoleMembers}, and mapping {roleMembers}*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |

#### Returns

| Name | Type | Description |
|---|---|---|
| count | uint256 |   Total number of accounts that have `role` |

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

### grantRole

```solidity
function grantRole(bytes32 role, address account) external nonpayable
```

Grants a role to an account, if not previously granted.

*Caller must have admin role for the `role`.                  Emits {RoleGranted Event}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |
| account | address | Address of the account to which the role is being granted. |

### hasRole

```solidity
function hasRole(bytes32 role, address account) external view returns (bool)
```

Checks whether an account has a particular role.

*Returns `true` if `account` has been granted `role`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |
| account | address | Address of the account for which the role is being checked. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### hasRoleWithSwitch

```solidity
function hasRoleWithSwitch(bytes32 role, address account) external view returns (bool)
```

Checks whether an account has a particular role;                  role restrictions can be swtiched on and off.

*Returns `true` if `account` has been granted `role`.                  Role restrictions can be swtiched on and off:                      - If address(0) has ROLE, then the ROLE restrictions                        don&#39;t apply.                      - If address(0) does not have ROLE, then the ROLE                        restrictions will apply.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |
| account | address | Address of the account for which the role is being checked. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### initialize

```solidity
function initialize(address _defaultAdmin, string _contractURI, address[] _trustedForwarders, address _rewardToken, address _stakingToken, uint256 _timeUnit, uint256 _rewardRatioNumerator, uint256 _rewardRatioDenominator) external nonpayable
```



*Initiliazes the contract, like a constructor.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _defaultAdmin | address | undefined |
| _contractURI | string | undefined |
| _trustedForwarders | address[] | undefined |
| _rewardToken | address | undefined |
| _stakingToken | address | undefined |
| _timeUnit | uint256 | undefined |
| _rewardRatioNumerator | uint256 | undefined |
| _rewardRatioDenominator | uint256 | undefined |

### isTrustedForwarder

```solidity
function isTrustedForwarder(address forwarder) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| forwarder | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### multicall

```solidity
function multicall(bytes[] data) external nonpayable returns (bytes[] results)
```



*Receives and executes a batch of function calls on this contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| results | bytes[] | undefined |

### renounceRole

```solidity
function renounceRole(bytes32 role, address account) external nonpayable
```

Revokes role from the account.

*Caller must have the `role`, with caller being the same as `account`.                  Emits {RoleRevoked Event}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |
| account | address | Address of the account from which the role is being revoked. |

### revokeRole

```solidity
function revokeRole(bytes32 role, address account) external nonpayable
```

Revokes role from an account.

*Caller must have admin role for the `role`.                  Emits {RoleRevoked Event}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |
| account | address | Address of the account from which the role is being revoked. |

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

### Initialized

```solidity
event Initialized(uint8 version)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### RewardTokensDepositedByAdmin

```solidity
event RewardTokensDepositedByAdmin(uint256 _amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount  | uint256 | undefined |

### RewardTokensWithdrawnByAdmin

```solidity
event RewardTokensWithdrawnByAdmin(uint256 _amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount  | uint256 | undefined |

### RewardsClaimed

```solidity
event RewardsClaimed(address indexed staker, uint256 rewardAmount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| staker `indexed` | address | undefined |
| rewardAmount  | uint256 | undefined |

### RoleAdminChanged

```solidity
event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| previousAdminRole `indexed` | bytes32 | undefined |
| newAdminRole `indexed` | bytes32 | undefined |

### RoleGranted

```solidity
event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| account `indexed` | address | undefined |
| sender `indexed` | address | undefined |

### RoleRevoked

```solidity
event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| account `indexed` | address | undefined |
| sender `indexed` | address | undefined |

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



