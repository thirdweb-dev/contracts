# IDirectListings

*thirdweb.com  The `DirectListings` extension smart contract lets you buy and sell NFTs (ERC-721 or ERC-1155) for a fixed price.*







## Methods

### approveBuyerForListing

```solidity
function approveBuyerForListing(uint256 _listingId, address _buyer, bool _toApprove) external nonpayable
```

Approve a buyer to buy from a reserved listing.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _listingId | uint256 | The ID of the listing to update. |
| _buyer | address | The address of the buyer to approve to buy from the listing. |
| _toApprove | bool | Whether to approve the buyer to buy from the listing. |

### approveCurrencyForListing

```solidity
function approveCurrencyForListing(uint256 _listingId, address _currency, uint256 _pricePerTokenInCurrency) external nonpayable
```

Approve a currency as a form of payment for the listing.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _listingId | uint256 | The ID of the listing to update. |
| _currency | address | The address of the currency to approve as a form of payment for the listing. |
| _pricePerTokenInCurrency | uint256 | The price per token for the currency to approve. |

### buyFromListing

```solidity
function buyFromListing(uint256 _listingId, address _buyFor, uint256 _quantity, address _currency, uint256 _expectedTotalPrice) external payable
```

Buy NFTs from a listing.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _listingId | uint256 | The ID of the listing to update. |
| _buyFor | address | The recipient of the NFTs being bought. |
| _quantity | uint256 | The quantity of NFTs to buy from the listing. |
| _currency | address | The currency to use to pay for NFTs. |
| _expectedTotalPrice | uint256 | The expected total price to pay for the NFTs being bought. |

### cancelListing

```solidity
function cancelListing(uint256 _listingId) external nonpayable
```

Cancel a listing.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _listingId | uint256 | The ID of the listing to cancel. |

### createListing

```solidity
function createListing(IDirectListings.ListingParameters _params) external nonpayable returns (uint256 listingId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _params | IDirectListings.ListingParameters | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| listingId | uint256 | undefined |

### getAllListings

```solidity
function getAllListings(uint256 _startId, uint256 _endId) external view returns (struct IDirectListings.Listing[] listings)
```

Returns all listings between the start and end Id (both inclusive) provided.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _startId | uint256 | undefined |
| _endId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| listings | IDirectListings.Listing[] | undefined |

### getAllValidListings

```solidity
function getAllValidListings(uint256 _startId, uint256 _endId) external view returns (struct IDirectListings.Listing[] listings)
```

Returns all valid listings between the start and end Id (both inclusive) provided.          A valid listing is where the listing creator still owns and has approved Marketplace          to transfer the listed NFTs.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _startId | uint256 | undefined |
| _endId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| listings | IDirectListings.Listing[] | undefined |

### getListing

```solidity
function getListing(uint256 _listingId) external view returns (struct IDirectListings.Listing listing)
```

Returns a listing at the provided listing ID.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _listingId | uint256 | The ID of the listing to fetch. |

#### Returns

| Name | Type | Description |
|---|---|---|
| listing | IDirectListings.Listing | undefined |

### totalListings

```solidity
function totalListings() external view returns (uint256)
```

Returns the total number of listings created.

*At any point, the return value is the ID of the next listing created.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### updateListing

```solidity
function updateListing(uint256 _listingId, IDirectListings.ListingParameters _params) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _listingId | uint256 | undefined |
| _params | IDirectListings.ListingParameters | undefined |



## Events

### BuyerApprovedForListing

```solidity
event BuyerApprovedForListing(uint256 indexed listingId, address indexed buyer, bool approved)
```

Emitted when a buyer is approved to buy from a reserved listing.



#### Parameters

| Name | Type | Description |
|---|---|---|
| listingId `indexed` | uint256 | undefined |
| buyer `indexed` | address | undefined |
| approved  | bool | undefined |

### CancelledListing

```solidity
event CancelledListing(address indexed listingCreator, uint256 indexed listingId)
```

Emitted when a listing is cancelled.



#### Parameters

| Name | Type | Description |
|---|---|---|
| listingCreator `indexed` | address | undefined |
| listingId `indexed` | uint256 | undefined |

### CurrencyApprovedForListing

```solidity
event CurrencyApprovedForListing(uint256 indexed listingId, address indexed currency, uint256 pricePerToken)
```

Emitted when a currency is approved as a form of payment for the listing.



#### Parameters

| Name | Type | Description |
|---|---|---|
| listingId `indexed` | uint256 | undefined |
| currency `indexed` | address | undefined |
| pricePerToken  | uint256 | undefined |

### NewListing

```solidity
event NewListing(address indexed listingCreator, uint256 indexed listingId, address indexed assetContract, IDirectListings.Listing listing)
```

Emitted when a new listing is created.



#### Parameters

| Name | Type | Description |
|---|---|---|
| listingCreator `indexed` | address | undefined |
| listingId `indexed` | uint256 | undefined |
| assetContract `indexed` | address | undefined |
| listing  | IDirectListings.Listing | undefined |

### NewSale

```solidity
event NewSale(address indexed listingCreator, uint256 indexed listingId, address indexed assetContract, uint256 tokenId, address buyer, uint256 quantityBought, uint256 totalPricePaid)
```

Emitted when NFTs are bought from a listing.



#### Parameters

| Name | Type | Description |
|---|---|---|
| listingCreator `indexed` | address | undefined |
| listingId `indexed` | uint256 | undefined |
| assetContract `indexed` | address | undefined |
| tokenId  | uint256 | undefined |
| buyer  | address | undefined |
| quantityBought  | uint256 | undefined |
| totalPricePaid  | uint256 | undefined |

### UpdatedListing

```solidity
event UpdatedListing(address indexed listingCreator, uint256 indexed listingId, address indexed assetContract, IDirectListings.Listing listing)
```

Emitted when a listing is updated.



#### Parameters

| Name | Type | Description |
|---|---|---|
| listingCreator `indexed` | address | undefined |
| listingId `indexed` | uint256 | undefined |
| assetContract `indexed` | address | undefined |
| listing  | IDirectListings.Listing | undefined |



