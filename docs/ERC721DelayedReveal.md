# ERC721DelayedReveal





BASE:      ERC721LazyMint      EXTENSION: DelayedReveal  The `ERC721DelayedReveal` contract uses the `ERC721LazyMint` contract, along with `DelayedReveal` extension.  &#39;Lazy minting&#39; means defining the metadata of NFTs without minting it to an address. Regular &#39;minting&#39;  of  NFTs means actually assigning an owner to an NFT.  As a contract admin, this lets you prepare the metadata for NFTs that will be minted by an external party,  without paying the gas cost for actually minting the NFTs.  &#39;Delayed reveal&#39; is a mechanism by which you can distribute NFTs to your audience and reveal the metadata of the distributed  NFTs, after the fact.  You can read more about how the `DelayedReveal` extension works, here: https://blog.thirdweb.com/delayed-reveal-nfts



## Methods

### OPERATOR_FILTER_REGISTRY

```solidity
function OPERATOR_FILTER_REGISTRY() external view returns (contract IOperatorFilterRegistry)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IOperatorFilterRegistry | undefined |

### approve

```solidity
function approve(address operator, uint256 tokenId) external nonpayable
```



*See {ERC721-approve}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | undefined |
| tokenId | uint256 | undefined |

### balanceOf

```solidity
function balanceOf(address owner) external view returns (uint256)
```



*See {IERC721-balanceOf}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### burn

```solidity
function burn(uint256 _tokenId) external nonpayable
```

Lets an owner or approved operator burn the NFT of the given tokenId.

*ERC721A&#39;s `_burn(uint256,bool)` internally checks for token approvals.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | The tokenId of the NFT to burn. |

### claim

```solidity
function claim(address _receiver, uint256 _quantity) external payable
```

Lets an address claim multiple lazy minted NFTs at once to a recipient.                   This function prevents any reentrant calls, and is not allowed to be overridden.                   Contract creators should override `verifyClaim` and `transferTokensOnClaim`                   functions to create custom logic for verification and claiming,                   for e.g. price collection, allowlist, max quantity, etc.

*The logic in `verifyClaim` determines whether the caller is authorized to mint NFTs.                   The logic in `transferTokensOnClaim` does actual minting of tokens,                   can also be used to apply other state changes.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _receiver | address | The recipient of the NFT to mint. |
| _quantity | uint256 | The number of NFTs to mint. |

### contractURI

```solidity
function contractURI() external view returns (string)
```

Returns the contract metadata URI.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### encryptDecrypt

```solidity
function encryptDecrypt(bytes data, bytes key) external pure returns (bytes result)
```

Encrypt/decrypt data on chain.

*Encrypt/decrypt given `data` with `key`. Uses inline assembly.                  See: https://ethereum.stackexchange.com/questions/69825/decrypt-message-on-chain*

#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes | Bytes of data to encrypt/decrypt. |
| key | bytes | Secure key used by caller for encryption/decryption. |

#### Returns

| Name | Type | Description |
|---|---|---|
| result | bytes |  Output after encryption/decryption of given data. |

### encryptedData

```solidity
function encryptedData(uint256) external view returns (bytes)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

### getApproved

```solidity
function getApproved(uint256 tokenId) external view returns (address)
```



*See {IERC721-getApproved}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

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

### getRevealURI

```solidity
function getRevealURI(uint256 _batchId, bytes _key) external view returns (string revealedURI)
```

Returns revealed URI for a batch of NFTs.

*Reveal encrypted base URI for `_batchId` with caller/admin&#39;s `_key` used for encryption.                      Reverts if there&#39;s no encrypted URI for `_batchId`.                      See {encryptDecrypt}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _batchId | uint256 | ID of the batch for which URI is being revealed. |
| _key | bytes | Secure key used by caller/admin for encryption of baseURI. |

#### Returns

| Name | Type | Description |
|---|---|---|
| revealedURI | string | Decrypted base URI. |

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
function isApprovedForAll(address owner, address operator) external view returns (bool)
```



*See {IERC721-isApprovedForAll}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |
| operator | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isEncryptedBatch

```solidity
function isEncryptedBatch(uint256 _batchId) external view returns (bool)
```

Returns whether the relvant batch of NFTs is subject to a delayed reveal.

*Returns `true` if `_batchId`&#39;s base URI is encrypted.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _batchId | uint256 | ID of a batch of NFTs. |

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
| _baseURIForTokens | string | The placeholder base URI for the &#39;n&#39; number of NFTs being lazy minted, where the                           metadata for each of those NFTs is `${baseURIForTokens}/${tokenId}`. |
| _data | bytes | The encrypted base URI + provenance hash for the batch of NFTs being lazy minted. |

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



*See {IERC721Metadata-name}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### nextTokenIdToClaim

```solidity
function nextTokenIdToClaim() external view returns (uint256)
```

The tokenId assigned to the next new NFT to be claimed.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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

### ownerOf

```solidity
function ownerOf(uint256 tokenId) external view returns (address)
```



*See {IERC721-ownerOf}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### reveal

```solidity
function reveal(uint256 _index, bytes _key) external nonpayable returns (string revealedURI)
```

Lets an authorized address reveal a batch of delayed reveal NFTs.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _index | uint256 | The ID for the batch of delayed-reveal NFTs to reveal. |
| _key | bytes | The key with which the base URI for the relevant batch of NFTs was encrypted. |

#### Returns

| Name | Type | Description |
|---|---|---|
| revealedURI | string | undefined |

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

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 tokenId) external nonpayable
```



*See {ERC721-_safeTransferFrom}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| tokenId | uint256 | undefined |

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 tokenId, bytes data) external nonpayable
```



*See {ERC721-_safeTransferFrom}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| tokenId | uint256 | undefined |
| data | bytes | undefined |

### setApprovalForAll

```solidity
function setApprovalForAll(address operator, bool approved) external nonpayable
```



*See {ERC721-setApprovalForAll}.*

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



*See ERC165: https://eips.ethereum.org/EIPS/eip-165*

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



*See {IERC721Metadata-symbol}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### tokenURI

```solidity
function tokenURI(uint256 _tokenId) external view returns (string)
```

Returns the metadata URI for an NFT.

*See `BatchMintMetadata` for handling of metadata in this contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | The tokenId of an NFT. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```



*Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 tokenId) external nonpayable
```



*See {ERC721-_transferFrom}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| tokenId | uint256 | undefined |

### verifyClaim

```solidity
function verifyClaim(address _claimer, uint256 _quantity) external view
```

Override this function to add logic for claim verification, based on conditions                   such as allowlist, price, max quantity etc.

*Checks a request to claim NFTs against a custom condition.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _claimer | address | Caller of the claim function. |
| _quantity | uint256 | The number of NFTs being claimed. |



## Events

### Approval

```solidity
event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | undefined |
| approved `indexed` | address | undefined |
| tokenId `indexed` | uint256 | undefined |

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

### TokenURIRevealed

```solidity
event TokenURIRevealed(uint256 indexed index, string revealedURI)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| index `indexed` | uint256 | undefined |
| revealedURI  | string | undefined |

### TokensClaimed

```solidity
event TokensClaimed(address indexed claimer, address indexed receiver, uint256 indexed startTokenId, uint256 quantityClaimed)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| startTokenId `indexed` | uint256 | undefined |
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

### Transfer

```solidity
event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| tokenId `indexed` | uint256 | undefined |



## Errors

### ApprovalCallerNotOwnerNorApproved

```solidity
error ApprovalCallerNotOwnerNorApproved()
```

The caller must own the token or be an approved operator.




### ApprovalQueryForNonexistentToken

```solidity
error ApprovalQueryForNonexistentToken()
```

The token does not exist.




### ApprovalToCurrentOwner

```solidity
error ApprovalToCurrentOwner()
```

The caller cannot approve to the current owner.




### ApproveToCaller

```solidity
error ApproveToCaller()
```

The caller cannot approve to their own address.




### BalanceQueryForZeroAddress

```solidity
error BalanceQueryForZeroAddress()
```

Cannot query the balance for the zero address.




### MintToZeroAddress

```solidity
error MintToZeroAddress()
```

Cannot mint to the zero address.




### MintZeroQuantity

```solidity
error MintZeroQuantity()
```

The quantity of tokens minted must be more than zero.




### OperatorNotAllowed

```solidity
error OperatorNotAllowed(address operator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | undefined |

### OwnerQueryForNonexistentToken

```solidity
error OwnerQueryForNonexistentToken()
```

The token does not exist.




### TransferCallerNotOwnerNorApproved

```solidity
error TransferCallerNotOwnerNorApproved()
```

The caller must own the token or be an approved operator.




### TransferFromIncorrectOwner

```solidity
error TransferFromIncorrectOwner()
```

The token must be owned by `from`.




### TransferToNonERC721ReceiverImplementer

```solidity
error TransferToNonERC721ReceiverImplementer()
```

Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.




### TransferToZeroAddress

```solidity
error TransferToZeroAddress()
```

Cannot transfer to the zero address.




### URIQueryForNonexistentToken

```solidity
error URIQueryForNonexistentToken()
```

The token does not exist.





