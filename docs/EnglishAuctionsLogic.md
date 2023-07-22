# EnglishAuctionsLogic

*thirdweb.com*







## Methods

### _msgData

```solidity
function _msgData() external view returns (bytes)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

### _msgSender

```solidity
function _msgSender() external view returns (address sender)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| sender | address | undefined |

### bidInAuction

```solidity
function bidInAuction(uint256 _auctionId, uint256 _bidAmount) external payable
```

Bid in an active auction.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _auctionId | uint256 | The ID of the auction to bid in. |
| _bidAmount | uint256 | The bid amount in the currency specified by the auction. |

### cancelAuction

```solidity
function cancelAuction(uint256 _auctionId) external nonpayable
```



*Cancels an auction.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _auctionId | uint256 | undefined |

### collectAuctionPayout

```solidity
function collectAuctionPayout(uint256 _auctionId) external nonpayable
```

Distribute the winning bid amount to the auction creator.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _auctionId | uint256 | The ID of an auction. |

### collectAuctionTokens

```solidity
function collectAuctionTokens(uint256 _auctionId) external nonpayable
```

Distribute the auctioned NFTs to the winning bidder.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _auctionId | uint256 | The ID of an auction. |

### createAuction

```solidity
function createAuction(IEnglishAuctions.AuctionParameters _params) external nonpayable returns (uint256 auctionId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _params | IEnglishAuctions.AuctionParameters | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| auctionId | uint256 | undefined |

### getAllAuctions

```solidity
function getAllAuctions(uint256 _startId, uint256 _endId) external view returns (struct IEnglishAuctions.Auction[] _allAuctions)
```

Returns all non-cancelled auctions.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _startId | uint256 | undefined |
| _endId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _allAuctions | IEnglishAuctions.Auction[] | undefined |

### getAllValidAuctions

```solidity
function getAllValidAuctions(uint256 _startId, uint256 _endId) external view returns (struct IEnglishAuctions.Auction[] _validAuctions)
```

Returns all active auctions.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _startId | uint256 | undefined |
| _endId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _validAuctions | IEnglishAuctions.Auction[] | undefined |

### getAuction

```solidity
function getAuction(uint256 _auctionId) external view returns (struct IEnglishAuctions.Auction _auction)
```

Returns the auction of the provided auction ID.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _auctionId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _auction | IEnglishAuctions.Auction | undefined |

### getWinningBid

```solidity
function getWinningBid(uint256 _auctionId) external view returns (address _bidder, address _currency, uint256 _bidAmount)
```

Returns the winning bid of an active auction.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _auctionId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _bidder | address | undefined |
| _currency | address | undefined |
| _bidAmount | uint256 | undefined |

### isAuctionExpired

```solidity
function isAuctionExpired(uint256 _auctionId) external view returns (bool)
```

Returns whether an auction is active.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _auctionId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isNewWinningBid

```solidity
function isNewWinningBid(uint256 _auctionId, uint256 _bidAmount) external view returns (bool)
```

Returns whether a given bid amount would make for a winning bid in an auction.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _auctionId | uint256 | The ID of an auction. |
| _bidAmount | uint256 | The bid amount to check. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### totalAuctions

```solidity
function totalAuctions() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |



## Events

### AuctionClosed

```solidity
event AuctionClosed(uint256 indexed auctionId, address indexed assetContract, address indexed closer, uint256 tokenId, address auctionCreator, address winningBidder)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| auctionId `indexed` | uint256 | undefined |
| assetContract `indexed` | address | undefined |
| closer `indexed` | address | undefined |
| tokenId  | uint256 | undefined |
| auctionCreator  | address | undefined |
| winningBidder  | address | undefined |

### CancelledAuction

```solidity
event CancelledAuction(address indexed auctionCreator, uint256 indexed auctionId)
```

Emitted when a auction is cancelled.



#### Parameters

| Name | Type | Description |
|---|---|---|
| auctionCreator `indexed` | address | undefined |
| auctionId `indexed` | uint256 | undefined |

### NewAuction

```solidity
event NewAuction(address indexed auctionCreator, uint256 indexed auctionId, address indexed assetContract, IEnglishAuctions.Auction auction)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| auctionCreator `indexed` | address | undefined |
| auctionId `indexed` | uint256 | undefined |
| assetContract `indexed` | address | undefined |
| auction  | IEnglishAuctions.Auction | undefined |

### NewBid

```solidity
event NewBid(uint256 indexed auctionId, address indexed bidder, address indexed assetContract, uint256 bidAmount, IEnglishAuctions.Auction auction)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| auctionId `indexed` | uint256 | undefined |
| bidder `indexed` | address | undefined |
| assetContract `indexed` | address | undefined |
| bidAmount  | uint256 | undefined |
| auction  | IEnglishAuctions.Auction | undefined |



