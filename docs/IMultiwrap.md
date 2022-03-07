# IMultiwrap









## Methods

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

### getDefaultRoyaltyInfo

```solidity
function getDefaultRoyaltyInfo() external view returns (address, uint16)
```



*Returns the royalty recipient and fee bps.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined
| _1 | uint16 | undefined

### getRoyaltyInfoForToken

```solidity
function getRoyaltyInfoForToken(uint256 tokenId) external view returns (address, uint16)
```



*Returns the royalty recipient for a particular token Id.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined
| _1 | uint16 | undefined

### owner

```solidity
function owner() external view returns (address)
```



*Returns the owner of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

### royaltyInfo

```solidity
function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount)
```



*Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of exchange. The royalty amount is denominated and should be payed in that same unit of exchange.*

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

### setContractURI

```solidity
function setContractURI(string _uri) external nonpayable
```



*Sets contract URI for the storefront-level metadata of the contract.       Only module admin can call this function.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _uri | string | undefined

### setDefaultRoyaltyInfo

```solidity
function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external nonpayable
```



*Lets a module admin update the royalty bps and recipient.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _royaltyRecipient | address | undefined
| _royaltyBps | uint256 | undefined

### setOwner

```solidity
function setOwner(address _newOwner) external nonpayable
```



*Lets a module admin set a new owner for the contract. The new owner must be a module admin.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _newOwner | address | undefined

### setRoyaltyInfoForToken

```solidity
function setRoyaltyInfoForToken(uint256 tokenId, address recipient, uint256 bps) external nonpayable
```



*Lets a module admin set the royalty recipient for a particular token Id.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined
| recipient | address | undefined
| bps | uint256 | undefined

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```



*Returns true if this contract implements the interface defined by `interfaceId`. See the corresponding https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section] to learn more about how these ids are created. This function call must use less than 30 000 gas.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| interfaceId | bytes4 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### unwrap

```solidity
function unwrap(uint256 tokenId, uint256 amountToRedeem, address _sendTo) external nonpayable
```

Unwrap shares to retrieve underlying ERC1155, ERC721, ERC20 tokens.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | The token Id of the tokens to unwrap.
| amountToRedeem | uint256 | The amount of shares to unwrap
| _sendTo | address | undefined

### wrap

```solidity
function wrap(MultiTokenTransferLib.MultiToken wrappedContents, uint256 shares, string uriForShares) external payable returns (uint256 tokenId)
```

Wrap multiple ERC1155, ERC721, ERC20 tokens into &#39;n&#39; shares (i.e. variable supply of 1 ERC 1155 token)



#### Parameters

| Name | Type | Description |
|---|---|---|
| wrappedContents | MultiTokenTransferLib.MultiToken | The tokens to wrap.
| shares | uint256 | The number of shares to issue for the wrapped contents.
| uriForShares | string | The URI for the shares i.e. wrapped token.

#### Returns

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined



## Events

### DefaultRoyalty

```solidity
event DefaultRoyalty(address newRoyaltyRecipient, uint256 newRoyaltyBps)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newRoyaltyRecipient  | address | undefined |
| newRoyaltyBps  | uint256 | undefined |

### OwnerUpdated

```solidity
event OwnerUpdated(address prevOwner, address newOwner)
```



*Emitted when a new Owner is set.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| prevOwner  | address | undefined |
| newOwner  | address | undefined |

### RoyaltyForToken

```solidity
event RoyaltyForToken(uint256 indexed tokenId, address royaltyRecipient, uint256 royaltyBps)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId `indexed` | uint256 | undefined |
| royaltyRecipient  | address | undefined |
| royaltyBps  | uint256 | undefined |

### TokensUnwrapped

```solidity
event TokensUnwrapped(address indexed wrapper, address sentTo, uint256 indexed tokenIdOfShares, uint256 sharesUnwrapped, MultiTokenTransferLib.MultiToken wrappedContents)
```



*Emitted when tokens are unwrapped.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| wrapper `indexed` | address | undefined |
| sentTo  | address | undefined |
| tokenIdOfShares `indexed` | uint256 | undefined |
| sharesUnwrapped  | uint256 | undefined |
| wrappedContents  | MultiTokenTransferLib.MultiToken | undefined |

### TokensWrapped

```solidity
event TokensWrapped(address indexed wrapper, uint256 indexed tokenIdOfShares, MultiTokenTransferLib.MultiToken wrappedContents)
```



*Emitted when tokens are wrapped.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| wrapper `indexed` | address | undefined |
| tokenIdOfShares `indexed` | uint256 | undefined |
| wrappedContents  | MultiTokenTransferLib.MultiToken | undefined |



