# MarketplaceAggregator









## Methods

### emitAcceptedOffer

```solidity
function emitAcceptedOffer(address offeror, uint256 offerId, address assetContract, uint256 tokenId, address seller, uint256 quantityBought, uint256 totalPricePaid) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| offeror | address | undefined |
| offerId | uint256 | undefined |
| assetContract | address | undefined |
| tokenId | uint256 | undefined |
| seller | address | undefined |
| quantityBought | uint256 | undefined |
| totalPricePaid | uint256 | undefined |

### emitAuctionClosed

```solidity
function emitAuctionClosed(uint256 auctionId, address assetContract, address closer, uint256 tokenId, address auctionCreator, address winningBidder) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| auctionId | uint256 | undefined |
| assetContract | address | undefined |
| closer | address | undefined |
| tokenId | uint256 | undefined |
| auctionCreator | address | undefined |
| winningBidder | address | undefined |

### emitBuyerApprovedForListing

```solidity
function emitBuyerApprovedForListing(uint256 listingId, address buyer, bool approved) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| listingId | uint256 | undefined |
| buyer | address | undefined |
| approved | bool | undefined |

### emitCancelAuction

```solidity
function emitCancelAuction(address auctionCreator, uint256 auctionId) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| auctionCreator | address | undefined |
| auctionId | uint256 | undefined |

### emitCancelListing

```solidity
function emitCancelListing(address listingCreator, uint256 listingId) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| listingCreator | address | undefined |
| listingId | uint256 | undefined |

### emitCancelOffer

```solidity
function emitCancelOffer(address offeror, uint256 offerId) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| offeror | address | undefined |
| offerId | uint256 | undefined |

### emitCurrencyApprovedForListing

```solidity
function emitCurrencyApprovedForListing(uint256 listingId, address currency, uint256 pricePerToken) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| listingId | uint256 | undefined |
| currency | address | undefined |
| pricePerToken | uint256 | undefined |

### emitNewAuction

```solidity
function emitNewAuction(address auctionCreator, uint256 auctionId, address assetContract, IEnglishAuctions.Auction auction) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| auctionCreator | address | undefined |
| auctionId | uint256 | undefined |
| assetContract | address | undefined |
| auction | IEnglishAuctions.Auction | undefined |

### emitNewBid

```solidity
function emitNewBid(uint256 auctionId, address bidder, address assetContract, uint256 bidAmount, IEnglishAuctions.Auction auction) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| auctionId | uint256 | undefined |
| bidder | address | undefined |
| assetContract | address | undefined |
| bidAmount | uint256 | undefined |
| auction | IEnglishAuctions.Auction | undefined |

### emitNewListing

```solidity
function emitNewListing(address listingCreator, uint256 listingId, address assetContract, IDirectListings.Listing listing) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| listingCreator | address | undefined |
| listingId | uint256 | undefined |
| assetContract | address | undefined |
| listing | IDirectListings.Listing | undefined |

### emitNewOffer

```solidity
function emitNewOffer(address offeror, uint256 offerId, address assetContract, IOffers.Offer offer) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| offeror | address | undefined |
| offerId | uint256 | undefined |
| assetContract | address | undefined |
| offer | IOffers.Offer | undefined |

### emitNewSale

```solidity
function emitNewSale(address listingCreator, uint256 listingId, address assetContract, uint256 tokenId, address buyer, uint256 quantityBought, uint256 totalPricePaid) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| listingCreator | address | undefined |
| listingId | uint256 | undefined |
| assetContract | address | undefined |
| tokenId | uint256 | undefined |
| buyer | address | undefined |
| quantityBought | uint256 | undefined |
| totalPricePaid | uint256 | undefined |

### emitUpdateListing

```solidity
function emitUpdateListing(address listingCreator, uint256 listingId, address assetContract, IDirectListings.Listing listing) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| listingCreator | address | undefined |
| listingId | uint256 | undefined |
| assetContract | address | undefined |
| listing | IDirectListings.Listing | undefined |



## Events

### AcceptedOffer

```solidity
event AcceptedOffer(address indexed marketplace, address indexed offeror, uint256 indexed offerId, address assetContract, uint256 tokenId, address seller, uint256 quantityBought, uint256 totalPricePaid)
```



*Emitted when an offer is accepted.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| marketplace `indexed` | address | undefined |
| offeror `indexed` | address | undefined |
| offerId `indexed` | uint256 | undefined |
| assetContract  | address | undefined |
| tokenId  | uint256 | undefined |
| seller  | address | undefined |
| quantityBought  | uint256 | undefined |
| totalPricePaid  | uint256 | undefined |

### AuctionClosed

```solidity
event AuctionClosed(address indexed marketplace, uint256 indexed auctionId, address indexed assetContract, address closer, uint256 tokenId, address auctionCreator, address winningBidder)
```



*Emitted when an auction is closed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| marketplace `indexed` | address | undefined |
| auctionId `indexed` | uint256 | undefined |
| assetContract `indexed` | address | undefined |
| closer  | address | undefined |
| tokenId  | uint256 | undefined |
| auctionCreator  | address | undefined |
| winningBidder  | address | undefined |

### BuyerApprovedForListing

```solidity
event BuyerApprovedForListing(address indexed marketplace, uint256 indexed listingId, address indexed buyer, bool approved)
```

Emitted when a buyer is approved to buy from a reserved listing.



#### Parameters

| Name | Type | Description |
|---|---|---|
| marketplace `indexed` | address | undefined |
| listingId `indexed` | uint256 | undefined |
| buyer `indexed` | address | undefined |
| approved  | bool | undefined |

### CancelledAuction

```solidity
event CancelledAuction(address indexed marketplace, address indexed auctionCreator, uint256 indexed auctionId)
```

Emitted when a auction is cancelled.



#### Parameters

| Name | Type | Description |
|---|---|---|
| marketplace `indexed` | address | undefined |
| auctionCreator `indexed` | address | undefined |
| auctionId `indexed` | uint256 | undefined |

### CancelledListing

```solidity
event CancelledListing(address indexed marketplace, address indexed listingCreator, uint256 indexed listingId)
```

Emitted when a listing is cancelled.



#### Parameters

| Name | Type | Description |
|---|---|---|
| marketplace `indexed` | address | undefined |
| listingCreator `indexed` | address | undefined |
| listingId `indexed` | uint256 | undefined |

### CancelledOffer

```solidity
event CancelledOffer(address indexed marketplace, address indexed offeror, uint256 indexed offerId)
```



*Emitted when an offer is cancelled.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| marketplace `indexed` | address | undefined |
| offeror `indexed` | address | undefined |
| offerId `indexed` | uint256 | undefined |

### CurrencyApprovedForListing

```solidity
event CurrencyApprovedForListing(address indexed marketplace, uint256 indexed listingId, address indexed currency, uint256 pricePerToken)
```

Emitted when a currency is approved as a form of payment for the listing.



#### Parameters

| Name | Type | Description |
|---|---|---|
| marketplace `indexed` | address | undefined |
| listingId `indexed` | uint256 | undefined |
| currency `indexed` | address | undefined |
| pricePerToken  | uint256 | undefined |

### NewAuction

```solidity
event NewAuction(address indexed marketplace, address indexed auctionCreator, uint256 indexed auctionId, address assetContract, IEnglishAuctions.Auction auction)
```



*Emitted when a new auction is created.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| marketplace `indexed` | address | undefined |
| auctionCreator `indexed` | address | undefined |
| auctionId `indexed` | uint256 | undefined |
| assetContract  | address | undefined |
| auction  | IEnglishAuctions.Auction | undefined |

### NewBid

```solidity
event NewBid(address indexed marketplace, uint256 indexed auctionId, address indexed bidder, address assetContract, uint256 bidAmount, IEnglishAuctions.Auction auction)
```



*Emitted when a new bid is made in an auction.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| marketplace `indexed` | address | undefined |
| auctionId `indexed` | uint256 | undefined |
| bidder `indexed` | address | undefined |
| assetContract  | address | undefined |
| bidAmount  | uint256 | undefined |
| auction  | IEnglishAuctions.Auction | undefined |

### NewListing

```solidity
event NewListing(address indexed marketplace, address indexed listingCreator, uint256 indexed listingId, address assetContract, IDirectListings.Listing listing)
```

Emitted when a new listing is created.



#### Parameters

| Name | Type | Description |
|---|---|---|
| marketplace `indexed` | address | undefined |
| listingCreator `indexed` | address | undefined |
| listingId `indexed` | uint256 | undefined |
| assetContract  | address | undefined |
| listing  | IDirectListings.Listing | undefined |

### NewOffer

```solidity
event NewOffer(address indexed marketplace, address indexed offeror, uint256 indexed offerId, address assetContract, IOffers.Offer offer)
```



*Emitted when a new offer is created.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| marketplace `indexed` | address | undefined |
| offeror `indexed` | address | undefined |
| offerId `indexed` | uint256 | undefined |
| assetContract  | address | undefined |
| offer  | IOffers.Offer | undefined |

### NewSale

```solidity
event NewSale(address indexed marketplace, address indexed listingCreator, uint256 indexed listingId, address assetContract, uint256 tokenId, address buyer, uint256 quantityBought, uint256 totalPricePaid)
```

Emitted when NFTs are bought from a listing.



#### Parameters

| Name | Type | Description |
|---|---|---|
| marketplace `indexed` | address | undefined |
| listingCreator `indexed` | address | undefined |
| listingId `indexed` | uint256 | undefined |
| assetContract  | address | undefined |
| tokenId  | uint256 | undefined |
| buyer  | address | undefined |
| quantityBought  | uint256 | undefined |
| totalPricePaid  | uint256 | undefined |

### UpdatedListing

```solidity
event UpdatedListing(address indexed marketplace, address indexed listingCreator, uint256 indexed listingId, address assetContract, IDirectListings.Listing listing)
```

Emitted when a listing is updated.



#### Parameters

| Name | Type | Description |
|---|---|---|
| marketplace `indexed` | address | undefined |
| listingCreator `indexed` | address | undefined |
| listingId `indexed` | uint256 | undefined |
| assetContract  | address | undefined |
| listing  | IDirectListings.Listing | undefined |



