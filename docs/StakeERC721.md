# StakeERC721









## Methods

### claimRewards

```solidity
function claimRewards() external nonpayable
```






### nftCollection

```solidity
function nftCollection() external view returns (contract IERC721)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IERC721 | undefined |

### owner

```solidity
function owner() external view returns (address)
```



*Returns the address of the current owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.*


### rewardTokens

```solidity
function rewardTokens(uint256) external view returns (address assetContract, uint256 rewardAmount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| assetContract | address | undefined |
| rewardAmount | uint256 | undefined |

### setRewardsPerHour

```solidity
function setRewardsPerHour(uint256[] _newValues) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _newValues | uint256[] | undefined |

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
function stakers(address) external view returns (uint256 amountStaked, uint256 timeOfLastUpdate)
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

### totalRewardTokens

```solidity
function totalRewardTokens() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |

### userStakeInfo

```solidity
function userStakeInfo(address _user) external view returns (uint256 _tokensStaked, struct StakeERC721.RewardToken[] _availableRewards)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _user | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _tokensStaked | uint256 | undefined |
| _availableRewards | StakeERC721.RewardToken[] | undefined |

### withdraw

```solidity
function withdraw(uint256[] _tokenIds) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenIds | uint256[] | undefined |



## Events

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |



