# ERC1155LazyMint





BASE:      ERC1155Base      EXTENSION: LazyMint  The `ERC1155LazyMint` smart contract implements the ERC1155 NFT standard.  It includes the following additions to standard ERC1155 logic:      - Lazy minting      - Ability to mint NFTs via the provided `mintTo` and `batchMintTo` functions.      - Contract metadata for royalty support on platforms such as OpenSea that use        off-chain information to distribute roaylties.      - Ownership of the contract, with the ability to restrict certain functions to        only be called by the contract&#39;s owner.      - Multicall capability to perform multiple actions atomically      - EIP 2981 compliance for royalty support on NFT marketplaces.  The `ERC1155LazyMint` contract uses the `LazyMint` extension.  &#39;Lazy minting&#39; means defining the metadata of NFTs without minting it to an address. Regular &#39;minting&#39;  of  NFTs means actually assigning an owner to an NFT.  As a contract admin, this lets you prepare the metadata for NFTs that will be minted by an external party,  without paying the gas cost for actually minting the NFTs.



## Methods

### OPERATOR_FILTER_REGISTRY

```solidity
function OPERATOR_FILTER_REGISTRY() external view returns (contract IOperatorFilterRegistry)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IOperatorFilterRegistry | undefined |

### balanceOf

```solidity
function balanceOf(address, uint256) external view returns (uint256)
```

Get the balance of an account&#39;s Tokens.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### balanceOfBatch

```solidity
function balanceOfBatch(address[] accounts, uint256[] ids) external view returns (uint256[])
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| accounts | address[] | undefined |
| ids | uint256[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256[] | undefined |

### burn

```solidity
function burn(address _owner, uint256 _tokenId, uint256 _amount) external nonpayable
```

Lets an owner or approved operator burn NFTs of the given tokenId.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _owner | address | The owner of the NFT to burn. |
| _tokenId | uint256 | The tokenId of the NFT to burn. |
| _amount | uint256 | The amount of the NFT to burn. |

### burnBatch

```solidity
function burnBatch(address _owner, uint256[] _tokenIds, uint256[] _amounts) external nonpayable
```

Lets an owner or approved operator burn NFTs of the given tokenIds.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _owner | address | The owner of the NFTs to burn. |
| _tokenIds | uint256[] | The tokenIds of the NFTs to burn. |
| _amounts | uint256[] | The amounts of the NFTs to burn. |

### claim

```solidity
function claim(address _receiver, uint256 _tokenId, uint256 _quantity) external payable
```

Lets an address claim multiple lazy minted NFTs at once to a recipient.                   This function prevents any reentrant calls, and is not allowed to be overridden.                   Contract creators should override `verifyClaim` and `transferTokensOnClaim`                   functions to create custom logic for verification and claiming,                   for e.g. price collection, allowlist, max quantity, etc.

*The logic in `verifyClaim` determines whether the caller is authorized to mint NFTs.                   The logic in `transferTokensOnClaim` does actual minting of tokens,                   can also be used to apply other state changes.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _receiver | address | The recipient of the tokens to mint. |
| _tokenId | uint256 | The tokenId of the lazy minted NFT to mint. |
| _quantity | uint256 | The number of tokens to mint. |

### contractURI

```solidity
function contractURI() external view returns (string)
```

Returns the contract metadata URI.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### getBaseURICount

```solidity
function getBaseURICount() external view returns (uint256)
```

Returns the count of batches of NFTs.

*Each batch of tokens has an in ID and an associated `baseURI`.                  See {batchIds}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getBatchIdAtIndex

```solidity
function getBatchIdAtIndex(uint256 _index) external view returns (uint256)
```

Returns the ID for the batch of tokens the given tokenId belongs to.

*See {getBaseURICount}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _index | uint256 | ID of a token. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getDefaultRoyaltyInfo

```solidity
function getDefaultRoyaltyInfo() external view returns (address, uint16)
```

Returns the defualt royalty recipient and BPS for this contract&#39;s NFTs.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | uint16 | undefined |

### getRoyaltyInfoForToken

```solidity
function getRoyaltyInfoForToken(uint256 _tokenId) external view returns (address, uint16)
```

View royalty info for a given token.

*Returns royalty recipient and bps for `_tokenId`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | The tokenID of the NFT for which to query royalty info. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | uint16 | undefined |

### isApprovedForAll

```solidity
function isApprovedForAll(address, address) external view returns (bool)
```

Queries the approval status of an operator for a given owner.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### lazyMint

```solidity
function lazyMint(uint256 _amount, string _baseURIForTokens, bytes _data) external nonpayable returns (uint256 batchId)
```

Lets an authorized address lazy mint a given amount of NFTs.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | The number of NFTs to lazy mint. |
| _baseURIForTokens | string | The base URI for the &#39;n&#39; number of NFTs being lazy minted, where the metadata for each                           of those NFTs is `${baseURIForTokens}/${tokenId}`. |
| _data | bytes | Additional bytes data to be used at the discretion of the consumer of the contract. |

#### Returns

| Name | Type | Description |
|---|---|---|
| batchId | uint256 |          A unique integer identifier for the batch of NFTs lazy minted together. |

### multicall

```solidity
function multicall(bytes[] data) external nonpayable returns (bytes[] results)
```

Receives and executes a batch of function calls on this contract.

*Receives and executes a batch of function calls on this contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes[] | The bytes data that makes up the batch of function calls to execute. |

#### Returns

| Name | Type | Description |
|---|---|---|
| results | bytes[] | The bytes data that makes up the result of the batch of function calls executed. |

### name

```solidity
function name() external view returns (string)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### nextTokenIdToMint

```solidity
function nextTokenIdToMint() external view returns (uint256)
```

The tokenId assigned to the next new NFT to be lazy minted.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### operatorRestriction

```solidity
function operatorRestriction() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### owner

```solidity
function owner() external view returns (address)
```

Returns the owner of the contract.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### royaltyInfo

```solidity
function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount)
```

View royalty info for a given token and sale price.

*Returns royalty amount and recipient for `tokenId` and `salePrice`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | The tokenID of the NFT for which to query royalty info. |
| salePrice | uint256 | Sale price of the token. |

#### Returns

| Name | Type | Description |
|---|---|---|
| receiver | address |        Address of royalty recipient account. |
| royaltyAmount | uint256 |   Royalty amount calculated at current royaltyBps value. |

### safeBatchTransferFrom

```solidity
function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] amounts, bytes data) external nonpayable
```



*See {IERC1155-safeBatchTransferFrom}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| ids | uint256[] | undefined |
| amounts | uint256[] | undefined |
| data | bytes | undefined |

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes data) external nonpayable
```



*See {IERC1155-safeTransferFrom}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| id | uint256 | undefined |
| amount | uint256 | undefined |
| data | bytes | undefined |

### setApprovalForAll

```solidity
function setApprovalForAll(address operator, bool approved) external nonpayable
```



*See {ERC1155-setApprovalForAll}*

#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | undefined |
| approved | bool | undefined |

### setContractURI

```solidity
function setContractURI(string _uri) external nonpayable
```

Lets a contract admin set the URI for contract-level metadata.

*Caller should be authorized to setup contractURI, e.g. contract admin.                  See {_canSetContractURI}.                  Emits {ContractURIUpdated Event}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _uri | string | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |

### setDefaultRoyaltyInfo

```solidity
function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external nonpayable
```

Updates default royalty recipient and bps.

*Caller should be authorized to set royalty info.                  See {_canSetRoyaltyInfo}.                  Emits {DefaultRoyalty Event}; See {_setupDefaultRoyaltyInfo}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _royaltyRecipient | address | Address to be set as default royalty recipient. |
| _royaltyBps | uint256 | Updated royalty bps. |

### setOperatorRestriction

```solidity
function setOperatorRestriction(bool _restriction) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _restriction | bool | undefined |

### setOwner

```solidity
function setOwner(address _newOwner) external nonpayable
```

Lets an authorized wallet set a new owner for the contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _newOwner | address | The address to set as the new owner of the contract. |

### setRoyaltyInfoForToken

```solidity
function setRoyaltyInfoForToken(uint256 _tokenId, address _recipient, uint256 _bps) external nonpayable
```

Updates default royalty recipient and bps for a particular token.

*Sets royalty info for `_tokenId`. Caller should be authorized to set royalty info.                  See {_canSetRoyaltyInfo}.                  Emits {RoyaltyForToken Event}; See {_setupRoyaltyInfoForToken}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined |
| _recipient | address | Address to be set as royalty recipient for given token Id. |
| _bps | uint256 | Updated royalty bps for the token Id. |

### subscribeToRegistry

```solidity
function subscribeToRegistry(address _subscription) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _subscription | address | undefined |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```

Returns whether this contract supports the given interface.



#### Parameters

| Name | Type | Description |
|---|---|---|
| interfaceId | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### symbol

```solidity
function symbol() external view returns (string)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### totalSupply

```solidity
function totalSupply(uint256) external view returns (uint256)
```

Returns the total supply of NFTs of a given tokenId

*Mapping from tokenId =&gt; total circulating supply of NFTs of that tokenId.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### uri

```solidity
function uri(uint256 _tokenId) external view returns (string)
```

Returns the metadata URI for the given tokenId.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### verifyClaim

```solidity
function verifyClaim(address _claimer, uint256 _tokenId, uint256 _quantity) external view
```

Override this function to add logic for claim verification, based on conditions                   such as allowlist, price, max quantity etc.

*Checks a request to claim NFTs against a custom condition.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _claimer | address | Caller of the claim function. |
| _tokenId | uint256 | The tokenId of the lazy minted NFT to mint. |
| _quantity | uint256 | The number of NFTs being claimed. |



## Events

### ApprovalForAll

```solidity
event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _owner `indexed` | address | undefined |
| _operator `indexed` | address | undefined |
| _approved  | bool | undefined |

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

### OperatorRestriction

```solidity
event OperatorRestriction(bool restriction)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| restriction  | bool | undefined |

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

### TokensClaimed

```solidity
event TokensClaimed(address indexed claimer, address indexed receiver, uint256 indexed tokenId, uint256 quantityClaimed)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId `indexed` | uint256 | undefined |
| quantityClaimed  | uint256 | undefined |

### TokensLazyMinted

```solidity
event TokensLazyMinted(uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes encryptedBaseURI)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| startTokenId `indexed` | uint256 | undefined |
| endTokenId  | uint256 | undefined |
| baseURI  | string | undefined |
| encryptedBaseURI  | bytes | undefined |

### TransferBatch

```solidity
event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _operator `indexed` | address | undefined |
| _from `indexed` | address | undefined |
| _to `indexed` | address | undefined |
| _ids  | uint256[] | undefined |
| _values  | uint256[] | undefined |

### TransferSingle

```solidity
event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _operator `indexed` | address | undefined |
| _from `indexed` | address | undefined |
| _to `indexed` | address | undefined |
| _id  | uint256 | undefined |
| _value  | uint256 | undefined |

### URI

```solidity
event URI(string _value, uint256 indexed _id)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _value  | string | undefined |
| _id `indexed` | uint256 | undefined |



## Errors

### OperatorNotAllowed

```solidity
error OperatorNotAllowed(address operator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | undefined |


