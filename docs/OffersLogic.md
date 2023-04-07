# OffersLogic

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
function getAllOffers(uint256 _startId, uint256 _endId) external view returns (struct IOffers.Offer[] _allOffers)
```



*Returns all existing offers within the specified range.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _startId | uint256 | undefined |
| _endId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _allOffers | IOffers.Offer[] | undefined |

### getAllValidOffers

```solidity
function getAllValidOffers(uint256 _startId, uint256 _endId) external view returns (struct IOffers.Offer[] _validOffers)
```



*Returns offers within the specified range, where offeror has sufficient balance.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _startId | uint256 | undefined |
| _endId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _validOffers | IOffers.Offer[] | undefined |

### getOffer

```solidity
function getOffer(uint256 _offerId) external view returns (struct IOffers.Offer _offer)
```



*Returns existing offer with the given uid.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _offerId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _offer | IOffers.Offer | undefined |

### makeOffer

```solidity
function makeOffer(IOffers.OfferParams _params) external nonpayable returns (uint256 _offerId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _params | IOffers.OfferParams | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _offerId | uint256 | undefined |

### totalOffers

```solidity
function totalOffers() external view returns (uint256)
```



*Returns total number of offers*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |



## Events

### AcceptedOffer

```solidity
event AcceptedOffer(address indexed offeror, uint256 indexed offerId, address indexed assetContract, uint256 tokenId, address seller, uint256 quantityBought, uint256 totalPricePaid)
```





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





#### Parameters

| Name | Type | Description |
|---|---|---|
| offeror `indexed` | address | undefined |
| offerId `indexed` | uint256 | undefined |

### NewOffer

```solidity
event NewOffer(address indexed offeror, uint256 indexed offerId, address indexed assetContract, IOffers.Offer offer)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| offeror `indexed` | address | undefined |
| offerId `indexed` | uint256 | undefined |
| assetContract `indexed` | address | undefined |
| offer  | IOffers.Offer | undefined |



