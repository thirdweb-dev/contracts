# IMarketplace









## Methods

### acceptOffer

```solidity
function acceptOffer(uint256 _listingId, address _offeror, address _currency, uint256 _totalPrice) external nonpayable
```

Lets a listing&#39;s creator accept an offer to their direct listing.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _listingId | uint256 | The unique ID of the listing for which to accept the offer.
| _offeror | address | The address of the buyer whose offer is to be accepted.
| _currency | address | The currency of the offer that is to be accepted.
| _totalPrice | uint256 | The total price of the offer that is to be accepted.

### buy

```solidity
function buy(uint256 _listingId, address _buyFor, uint256 _quantity, address _currency, uint256 _totalPrice) external payable
```

Lets someone buy a given quantity of tokens from a direct listing by paying the fixed price.

*A sale will fail to execute if either:          (1) buyer does not own or has not approved Marketplace to transfer the appropriate              amount of currency (or hasn&#39;t sent the appropriate amount of native tokens)          (2) the lister does not own or has removed Markeplace&#39;s              approval to transfer the tokens listed for sale.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _listingId | uint256 | The uid of the direct lisitng to buy from.
| _buyFor | address | The receiver of the NFT being bought.
| _quantity | uint256 | The amount of NFTs to buy from the direct listing.
| _currency | address | The currency to pay the price in.
| _totalPrice | uint256 | The total price to pay for the tokens being bought.

### cancelDirectListing

```solidity
function cancelDirectListing(uint256 _listingId) external nonpayable
```

Lets a direct listing creator cancel their listing.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _listingId | uint256 | The unique Id of the lisitng to cancel.

### closeAuction

```solidity
function closeAuction(uint256 _listingId, address _closeFor) external nonpayable
```

Lets any account close an auction on behalf of either the (1) auction&#39;s creator, or (2) winning bidder.              For (1): The auction creator is sent the the winning bid amount.              For (2): The winning bidder is sent the auctioned NFTs.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _listingId | uint256 | The uid of the listing (the auction to close).
| _closeFor | address | For whom the auction is being closed - the auction creator or winning bidder.

### contractType

```solidity
function contractType() external pure returns (bytes32)
```



*Returns the module type of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined

### contractURI

```solidity
function contractURI() external view returns (string)
```



*Returns the metadata URI of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined

### contractVersion

```solidity
function contractVersion() external pure returns (uint8)
```



*Returns the version of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint8 | undefined

### createListing

```solidity
function createListing(IMarketplace.ListingParameters _params) external nonpayable
```

Lets a token owner list tokens (ERC 721 or ERC 1155) for sale in a direct listing, or an auction.

*NFTs to list for sale in an auction are escrowed in Marketplace. For direct listings, the contract       only checks whether the listing&#39;s creator owns and has approved Marketplace to transfer the NFTs to list.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _params | IMarketplace.ListingParameters | The parameters that govern the listing to be created.

### getPlatformFeeInfo

```solidity
function getPlatformFeeInfo() external view returns (address platformFeeRecipient, uint16 platformFeeBps)
```



*Returns the platform fee bps and recipient.*


#### Returns

| Name | Type | Description |
|---|---|---|
| platformFeeRecipient | address | undefined
| platformFeeBps | uint16 | undefined

### offer

```solidity
function offer(uint256 _listingId, uint256 _quantityWanted, address _currency, uint256 _pricePerToken) external payable
```

Lets someone make an offer to a direct listing, or bid in an auction.

*Each (address, listing ID) pair maps to a single unique offer. So e.g. if a buyer makes       makes two offers to the same direct listing, the last offer is counted as the buyer&#39;s       offer to that listing.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _listingId | uint256 | The unique ID of the lisitng to make an offer/bid to.
| _quantityWanted | uint256 | For auction listings: the &#39;quantity wanted&#39; is the total amount of NFTs                           being auctioned, regardless of the value of `_quantityWanted` passed.                           For direct listings: `_quantityWanted` is the quantity of NFTs from the                           listing, for which the offer is being made.
| _currency | address | For auction listings: the &#39;currency of the bid&#39; is the currency accepted                           by the auction, regardless of the value of `_currency` passed. For direct                           listings: this is the currency in which the offer is made.
| _pricePerToken | uint256 | For direct listings: offered price per token. For auction listings: the bid                           amount per token. The total offer/bid amount is `_quantityWanted * _pricePerToken`.

### setContractURI

```solidity
function setContractURI(string _uri) external nonpayable
```



*Sets contract URI for the storefront-level metadata of the contract.       Only module admin can call this function.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _uri | string | undefined

### setPlatformFeeInfo

```solidity
function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external nonpayable
```



*Lets a module admin update the fees on primary sales.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _platformFeeRecipient | address | undefined
| _platformFeeBps | uint256 | undefined

### updateListing

```solidity
function updateListing(uint256 _listingId, uint256 _quantityToList, uint256 _reservePricePerToken, uint256 _buyoutPricePerToken, address _currencyToAccept, uint256 _startTime, uint256 _secondsUntilEndTime) external nonpayable
```

Lets a listing&#39;s creator edit the listing&#39;s parameters. A direct listing can be edited whenever.          An auction listing cannot be edited after the auction has started.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _listingId | uint256 | The uid of the lisitng to edit.
| _quantityToList | uint256 | The amount of NFTs to list for sale in the listing. For direct lisitngs, the contract                               only checks whether the listing creator owns and has approved Marketplace to transfer                               `_quantityToList` amount of NFTs to list for sale. For auction listings, the contract                               ensures that exactly `_quantityToList` amount of NFTs to list are escrowed.
| _reservePricePerToken | uint256 | For direct listings: this value is ignored. For auctions: the minimum bid amount of                               the auction is `reservePricePerToken * quantityToList`
| _buyoutPricePerToken | uint256 | For direct listings: interpreted as &#39;price per token&#39; listed. For auctions: if                               `buyoutPricePerToken` is greater than 0, and a bidder&#39;s bid is at least as great as                               `buyoutPricePerToken * quantityToList`, the bidder wins the auction, and the auction                               is closed.
| _currencyToAccept | address | For direct listings: the currency in which a buyer must pay the listing&#39;s fixed price                               to buy the NFT(s). For auctions: the currency in which the bidders must make bids.
| _startTime | uint256 | The unix timestamp after which listing is active. For direct listings:                               &#39;active&#39; means NFTs can be bought from the listing. For auctions,                               &#39;active&#39; means bids can be made in the auction.
| _secondsUntilEndTime | uint256 | No. of seconds after the provided `_startTime`, after which the listing is inactive.                               For direct listings: &#39;inactive&#39; means NFTs cannot be bought from the listing.                               For auctions: &#39;inactive&#39; means bids can no longer be made in the auction.



## Events

### AuctionBuffersUpdated

```solidity
event AuctionBuffersUpdated(uint256 timeBuffer, uint256 bidBufferBps)
```



*Emitted when auction buffers are updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| timeBuffer  | uint256 | undefined |
| bidBufferBps  | uint256 | undefined |

### AuctionClosed

```solidity
event AuctionClosed(uint256 indexed listingId, address indexed closer, bool indexed cancelled, address auctionCreator, address winningBidder)
```



*Emitted when an auction is closed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| listingId `indexed` | uint256 | undefined |
| closer `indexed` | address | undefined |
| cancelled `indexed` | bool | undefined |
| auctionCreator  | address | undefined |
| winningBidder  | address | undefined |

### ListingAdded

```solidity
event ListingAdded(uint256 indexed listingId, address indexed assetContract, address indexed lister, IMarketplace.Listing listing)
```



*Emitted when a new listing is created.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| listingId `indexed` | uint256 | undefined |
| assetContract `indexed` | address | undefined |
| lister `indexed` | address | undefined |
| listing  | IMarketplace.Listing | undefined |

### ListingRemoved

```solidity
event ListingRemoved(uint256 indexed listingId, address indexed listingCreator)
```



*Emitted when a listing is cancelled.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| listingId `indexed` | uint256 | undefined |
| listingCreator `indexed` | address | undefined |

### ListingUpdated

```solidity
event ListingUpdated(uint256 indexed listingId, address indexed listingCreator)
```



*Emitted when the parameters of a listing are updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| listingId `indexed` | uint256 | undefined |
| listingCreator `indexed` | address | undefined |

### NewOffer

```solidity
event NewOffer(uint256 indexed listingId, address indexed offeror, enum IMarketplace.ListingType indexed listingType, uint256 quantityWanted, uint256 totalOfferAmount, address currency)
```



*Emitted when (1) a new offer is made to a direct listing, or (2) when a new bid is made in an auction.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| listingId `indexed` | uint256 | undefined |
| offeror `indexed` | address | undefined |
| listingType `indexed` | enum IMarketplace.ListingType | undefined |
| quantityWanted  | uint256 | undefined |
| totalOfferAmount  | uint256 | undefined |
| currency  | address | undefined |

### NewSale

```solidity
event NewSale(uint256 indexed listingId, address indexed assetContract, address indexed lister, address buyer, uint256 quantityBought, uint256 totalPricePaid)
```



*Emitted when a buyer buys from a direct listing, or a lister accepts some      buyer&#39;s offer to their direct listing.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| listingId `indexed` | uint256 | undefined |
| assetContract `indexed` | address | undefined |
| lister `indexed` | address | undefined |
| buyer  | address | undefined |
| quantityBought  | uint256 | undefined |
| totalPricePaid  | uint256 | undefined |

### PlatformFeeInfoUpdated

```solidity
event PlatformFeeInfoUpdated(address platformFeeRecipient, uint256 platformFeeBps)
```



*Emitted when fee on primary sales is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| platformFeeRecipient  | address | undefined |
| platformFeeBps  | uint256 | undefined |



