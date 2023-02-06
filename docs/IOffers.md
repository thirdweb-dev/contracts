# IOffers





The `Offers` extension smart contract lets you make and accept offers made for NFTs (ERC-721 or ERC-1155).



## Methods

### acceptOffer

```solidity
function acceptOffer(uint256 _offerId) external nonpayable
```

Accept an offer.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _offerId | uint256 | The ID of the offer to accept. |

### cancelOffer

```solidity
function cancelOffer(uint256 _offerId) external nonpayable
```

Cancel an offer.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _offerId | uint256 | The ID of the offer to cancel. |

### getAllOffers

```solidity
function getAllOffers(uint256 _startId, uint256 _endId) external view returns (struct IOffers.Offer[] offers)
```

Returns all active (i.e. non-expired or cancelled) offers.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _startId | uint256 | undefined |
| _endId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| offers | IOffers.Offer[] | undefined |

### getAllValidOffers

```solidity
function getAllValidOffers(uint256 _startId, uint256 _endId) external view returns (struct IOffers.Offer[] offers)
```

Returns all valid offers. An offer is valid if the offeror owns and has approved Marketplace to transfer the offer amount of currency.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _startId | uint256 | undefined |
| _endId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| offers | IOffers.Offer[] | undefined |

### getOffer

```solidity
function getOffer(uint256 _offerId) external view returns (struct IOffers.Offer offer)
```

Returns an offer for the given offer ID.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _offerId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| offer | IOffers.Offer | undefined |

### makeOffer

```solidity
function makeOffer(IOffers.OfferParams _params) external nonpayable returns (uint256 offerId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _params | IOffers.OfferParams | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| offerId | uint256 | undefined |



## Events

### AcceptedOffer

```solidity
event AcceptedOffer(address indexed offeror, uint256 indexed offerId, address indexed assetContract, uint256 tokenId, address seller, uint256 quantityBought, uint256 totalPricePaid)
```



*Emitted when an offer is accepted.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| offeror `indexed` | address | undefined |
| offerId `indexed` | uint256 | undefined |
| assetContract `indexed` | address | undefined |
| tokenId  | uint256 | undefined |
| seller  | address | undefined |
| quantityBought  | uint256 | undefined |
| totalPricePaid  | uint256 | undefined |

### CancelledOffer

```solidity
event CancelledOffer(address indexed offeror, uint256 indexed offerId)
```



*Emitted when an offer is cancelled.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| offeror `indexed` | address | undefined |
| offerId `indexed` | uint256 | undefined |

### NewOffer

```solidity
event NewOffer(address indexed offeror, uint256 indexed offerId, address indexed assetContract, IOffers.Offer offer)
```



*Emitted when a new offer is created.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| offeror `indexed` | address | undefined |
| offerId `indexed` | uint256 | undefined |
| assetContract `indexed` | address | undefined |
| offer  | IOffers.Offer | undefined |



