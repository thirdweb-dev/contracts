# IPack





The thirdweb `Pack` contract is a lootbox mechanism. An account can bundle up arbitrary ERC20, ERC721 and ERC1155 tokens into  a set of packs. A pack can then be opened in return for a selection of the tokens in the pack. The selection of tokens distributed  on opening a pack depends on the relative supply of all tokens in the packs.



## Methods

### createPack

```solidity
function createPack(IPack.PackContent[] contents, string packUri, uint128 openStartTimestamp, uint128 amountDistributedPerOpen, address recipient) external nonpayable returns (uint256 packId, uint256 packTotalSupply)
```

Creates a pack with the stated contents.



#### Parameters

| Name | Type | Description |
|---|---|---|
| contents | IPack.PackContent[] | The reward units to pack in the packs.
| packUri | string | The (metadata) URI assigned to the packs created.
| openStartTimestamp | uint128 | The timestamp after which packs can be opened.
| amountDistributedPerOpen | uint128 | The number of reward units distributed per open.
| recipient | address | The recipient of the packs created.

#### Returns

| Name | Type | Description |
|---|---|---|
| packId | uint256 | The unique identifer of the created set of packs.
| packTotalSupply | uint256 | The total number of packs created.

### openPack

```solidity
function openPack(uint256 packId, uint256 amountToOpen) external nonpayable
```

Lets a pack owner open a pack and receive the pack&#39;s reward unit.



#### Parameters

| Name | Type | Description |
|---|---|---|
| packId | uint256 | The identifier of the pack to open.
| amountToOpen | uint256 | The number of packs to open at once.



## Events

### OwnerUpdated

```solidity
event OwnerUpdated(address prevOwner, address newOwner)
```



*Emitted when the owner is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| prevOwner  | address | undefined |
| newOwner  | address | undefined |

### PackCreated

```solidity
event PackCreated(uint256 indexed packId, address indexed packCreator, address recipient, IPack.PackInfo packInfo, uint256 totalPacksCreated)
```

Emitted when a set of packs is created.



#### Parameters

| Name | Type | Description |
|---|---|---|
| packId `indexed` | uint256 | undefined |
| packCreator `indexed` | address | undefined |
| recipient  | address | undefined |
| packInfo  | IPack.PackInfo | undefined |
| totalPacksCreated  | uint256 | undefined |

<<<<<<< HEAD
### OwnerUpdated

```solidity
event OwnerUpdated(address prevOwner, address newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prevOwner  | address | undefined |
| newOwner  | address | undefined |

### RoyaltyForToken
=======
### PackOpened
>>>>>>> pack

```solidity
event PackOpened(uint256 indexed packId, address indexed opener, uint256 numOfPacksOpened, IPack.PackContent[] rewardUnitsDistributed)
```

Emitted when a pack is opened.



#### Parameters

| Name | Type | Description |
|---|---|---|
| packId `indexed` | uint256 | undefined |
| opener `indexed` | address | undefined |
| numOfPacksOpened  | uint256 | undefined |
| rewardUnitsDistributed  | IPack.PackContent[] | undefined |



