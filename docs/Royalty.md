# Royalty





Thirdweb&#39;s `Royalty` is a contract extension to be used with any base contract. It exposes functions for setting and reading  the recipient of royalty fee and the royalty fee basis points, and lets the inheriting contract perform conditional logic  that uses information about royalty fees, if desired.  The `Royalty` contract is ERC2981 compliant.



## Methods

### getDefaultRoyaltyInfo

```solidity
function getDefaultRoyaltyInfo() external view returns (address, uint16)
```



*Returns the default royalty recipient and bps.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined
| _1 | uint16 | undefined

### getRoyaltyInfoForToken

```solidity
function getRoyaltyInfoForToken(uint256 _tokenId) external view returns (address, uint16)
```



*Returns the royalty recipient and bps for a particular token Id.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined
| _1 | uint16 | undefined

### royaltyInfo

```solidity
function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount)
```



*Returns the royalty recipient and amount, given a tokenId and sale price.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined
| salePrice | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| receiver | address | undefined
| royaltyAmount | uint256 | undefined

### setDefaultRoyaltyInfo

```solidity
function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external nonpayable
```



*Lets a contract admin update the default royalty recipient and bps.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _royaltyRecipient | address | undefined
| _royaltyBps | uint256 | undefined

### setRoyaltyInfoForToken

```solidity
function setRoyaltyInfoForToken(uint256 _tokenId, address _recipient, uint256 _bps) external nonpayable
```



*Lets a contract admin set the royalty recipient and bps for a particular token Id.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined
| _recipient | address | undefined
| _bps | uint256 | undefined



## Events

### DefaultRoyalty

```solidity
event DefaultRoyalty(address indexed newRoyaltyRecipient, uint256 newRoyaltyBps)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newRoyaltyRecipient `indexed` | address | undefined |
| newRoyaltyBps  | uint256 | undefined |

### RoyaltyForToken

```solidity
event RoyaltyForToken(uint256 indexed tokenId, address indexed royaltyRecipient, uint256 royaltyBps)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId `indexed` | uint256 | undefined |
| royaltyRecipient `indexed` | address | undefined |
| royaltyBps  | uint256 | undefined |



## Errors

### Royalty__ExceedsMaxBps

```solidity
error Royalty__ExceedsMaxBps(uint256 royaltyBps)
```

Emitted when the given bps exceeds max bps.



#### Parameters

| Name | Type | Description |
|---|---|---|
| royaltyBps | uint256 | undefined |

### Royalty__NotAuthorized

```solidity
error Royalty__NotAuthorized()
```



*Emitted when an unauthorized caller tries to set royalty details.*



