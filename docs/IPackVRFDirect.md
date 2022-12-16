# IPackVRFDirect





The thirdweb `Pack` contract is a lootbox mechanism. An account can bundle up arbitrary ERC20, ERC721 and ERC1155 tokens into  a set of packs. A pack can then be opened in return for a selection of the tokens in the pack. The selection of tokens distributed  on opening a pack depends on the relative supply of all tokens in the packs.



## Methods

### canClaimRewards

```solidity
function canClaimRewards(address _opener) external view returns (bool)
```

Returns whether a pack opener is ready to call `claimRewards`.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _opener | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### claimRewards

```solidity
function claimRewards() external nonpayable returns (struct ITokenBundle.Token[] rewardUnits)
```

Called by a pack opener to claim rewards from the opened pack.




#### Returns

| Name | Type | Description |
|---|---|---|
| rewardUnits | ITokenBundle.Token[] | undefined |

### createPack

```solidity
function createPack(ITokenBundle.Token[] contents, uint256[] numOfRewardUnits, string packUri, uint128 openStartTimestamp, uint128 amountDistributedPerOpen, address recipient) external payable returns (uint256 packId, uint256 packTotalSupply)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| contents | ITokenBundle.Token[] | undefined |
| numOfRewardUnits | uint256[] | undefined |
| packUri | string | undefined |
| openStartTimestamp | uint128 | undefined |
| amountDistributedPerOpen | uint128 | undefined |
| recipient | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| packId | uint256 | undefined |
| packTotalSupply | uint256 | undefined |

### openPack

```solidity
function openPack(uint256 packId, uint256 amountToOpen) external nonpayable returns (uint256 requestId)
```

Lets a pack owner request to open a pack.



#### Parameters

| Name | Type | Description |
|---|---|---|
| packId | uint256 | The identifier of the pack to open. |
| amountToOpen | uint256 | The number of packs to open at once. |

#### Returns

| Name | Type | Description |
|---|---|---|
| requestId | uint256 | undefined |

### openPackAndClaimRewards

```solidity
function openPackAndClaimRewards(uint256 _packId, uint256 _amountToOpen, uint32 _callBackGasLimit) external nonpayable returns (uint256)
```

Called by a pack opener to open a pack in a single transaction, instead of calling openPack and claimRewards separately.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _packId | uint256 | undefined |
| _amountToOpen | uint256 | undefined |
| _callBackGasLimit | uint32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |



## Events

### PackCreated

```solidity
event PackCreated(uint256 indexed packId, address recipient, uint256 totalPacksCreated)
```

Emitted when a set of packs is created.



#### Parameters

| Name | Type | Description |
|---|---|---|
| packId `indexed` | uint256 | undefined |
| recipient  | address | undefined |
| totalPacksCreated  | uint256 | undefined |

### PackOpenRequested

```solidity
event PackOpenRequested(address indexed opener, uint256 indexed packId, uint256 amountToOpen, uint256 requestId)
```

Emitted when the opening of a pack is requested.



#### Parameters

| Name | Type | Description |
|---|---|---|
| opener `indexed` | address | undefined |
| packId `indexed` | uint256 | undefined |
| amountToOpen  | uint256 | undefined |
| requestId  | uint256 | undefined |

### PackOpened

```solidity
event PackOpened(uint256 indexed packId, address indexed opener, uint256 numOfPacksOpened, ITokenBundle.Token[] rewardUnitsDistributed)
```

Emitted when a pack is opened.



#### Parameters

| Name | Type | Description |
|---|---|---|
| packId `indexed` | uint256 | undefined |
| opener `indexed` | address | undefined |
| numOfPacksOpened  | uint256 | undefined |
| rewardUnitsDistributed  | ITokenBundle.Token[] | undefined |

### PackRandomnessFulfilled

```solidity
event PackRandomnessFulfilled(uint256 indexed packId, uint256 indexed requestId)
```

Emitted when Chainlink VRF fulfills a random number request.



#### Parameters

| Name | Type | Description |
|---|---|---|
| packId `indexed` | uint256 | undefined |
| requestId `indexed` | uint256 | undefined |



