# IPack





The thirdweb `Pack` contract is a lootbox mechanism. An account can bundle up arbitrary ERC20, ERC721 and ERC1155 tokens into  a set of packs. A pack can then be opened in return for a selection of the tokens in the pack. The selection of tokens distributed  on opening a pack depends on the relative supply of all tokens in the packs.



## Methods

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
function openPack(uint256 packId, uint256 amountToOpen) external nonpayable returns (struct ITokenBundle.Token[])
```

Lets a pack owner open a pack and receive the pack&#39;s reward unit.



#### Parameters

| Name | Type | Description |
|---|---|---|
| packId | uint256 | The identifier of the pack to open. |
| amountToOpen | uint256 | The number of packs to open at once. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | ITokenBundle.Token[] | undefined |



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

### PackUpdated

```solidity
event PackUpdated(uint256 indexed packId, address recipient, uint256 totalPacksCreated)
```

Emitted when more packs are minted for a packId.



#### Parameters

| Name | Type | Description |
|---|---|---|
| packId `indexed` | uint256 | undefined |
| recipient  | address | undefined |
| totalPacksCreated  | uint256 | undefined |



