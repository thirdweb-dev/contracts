# ERC1155Base









## Methods

### balanceOf

```solidity
function balanceOf(address, uint256) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined
| _1 | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### balanceOfBatch

```solidity
function balanceOfBatch(address[] owners, uint256[] ids) external view returns (uint256[] balances)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| owners | address[] | undefined
| ids | uint256[] | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| balances | uint256[] | undefined

### contractURI

```solidity
function contractURI() external view returns (string)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined

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

### isApprovedForAll

```solidity
function isApprovedForAll(address, address) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined
| _1 | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### mint

```solidity
function mint(address _to, uint256 _tokenId, string _tokenURI, uint256 _amount, bytes _data) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _to | address | undefined
| _tokenId | uint256 | undefined
| _tokenURI | string | undefined
| _amount | uint256 | undefined
| _data | bytes | undefined

### multicall

```solidity
function multicall(bytes[] data) external nonpayable returns (bytes[] results)
```



*Receives and executes a batch of function calls on this contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes[] | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| results | bytes[] | undefined

### name

```solidity
function name() external view returns (string)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined

### nextTokenIdToMint

```solidity
function nextTokenIdToMint() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

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

### safeBatchTransferFrom

```solidity
function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] amounts, bytes data) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined
| to | address | undefined
| ids | uint256[] | undefined
| amounts | uint256[] | undefined
| data | bytes | undefined

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes data) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined
| to | address | undefined
| id | uint256 | undefined
| amount | uint256 | undefined
| data | bytes | undefined

### setApprovalForAll

```solidity
function setApprovalForAll(address operator, bool approved) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | undefined
| approved | bool | undefined

### setContractURI

```solidity
function setContractURI(string _uri) external nonpayable
```



*Lets a contract admin set the URI for contract-level metadata.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _uri | string | undefined

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

### setOwner

```solidity
function setOwner(address _newOwner) external nonpayable
```



*Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _newOwner | address | undefined

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

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| interfaceId | bytes4 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### symbol

```solidity
function symbol() external view returns (string)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined

### totalSupply

```solidity
function totalSupply(uint256) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### uri

```solidity
function uri(uint256 id) external view returns (string)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined



## Events

### ApprovalForAll

```solidity
event ApprovalForAll(address indexed owner, address indexed operator, bool approved)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | undefined |
| operator `indexed` | address | undefined |
| approved  | bool | undefined |

### ContractURIUpdated

```solidity
event ContractURIUpdated(string prevURI, string newURI)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prevURI  | string | undefined |
| newURI  | string | undefined |

### DefaultRoyalty

```solidity
event DefaultRoyalty(address indexed newRoyaltyRecipient, uint256 newRoyaltyBps)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newRoyaltyRecipient `indexed` | address | undefined |
| newRoyaltyBps  | uint256 | undefined |

### OwnerUpdated

```solidity
event OwnerUpdated(address indexed prevOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prevOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

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

### TransferBatch

```solidity
event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] amounts)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| operator `indexed` | address | undefined |
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| ids  | uint256[] | undefined |
| amounts  | uint256[] | undefined |

### TransferSingle

```solidity
event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| operator `indexed` | address | undefined |
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| id  | uint256 | undefined |
| amount  | uint256 | undefined |

### URI

```solidity
event URI(string value, uint256 indexed id)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| value  | string | undefined |
| id `indexed` | uint256 | undefined |



## Errors

### ContractMetadata__NotAuthorized

```solidity
error ContractMetadata__NotAuthorized()
```



*Emitted when an unauthorized caller tries to set the contract metadata URI.*


### Ownable__NotAuthorized

```solidity
error Ownable__NotAuthorized()
```



*Emitted when an unauthorized caller tries to set the owner.*


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



