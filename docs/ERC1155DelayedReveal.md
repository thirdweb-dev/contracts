# ERC1155DelayedReveal









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

### batchMintTo

```solidity
function batchMintTo(address _to, uint256[] _tokenIds, uint256[] _amounts, string) external nonpayable
```

Lets an authorized address mint multiple lazy minted NFTs at once to a recipient.

*The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _to | address | The recipient of the NFT to mint.
| _tokenIds | uint256[] | The tokenIds of the NFTs to mint.
| _amounts | uint256[] | The amounts of each NFT to mint.
| _3 | string | undefined

### burn

```solidity
function burn(address _owner, uint256 _tokenId, uint256 _amount) external nonpayable
```

Lets an owner or approved operator burn NFTs of the given tokenId.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _owner | address | The owner of the NFT to burn.
| _tokenId | uint256 | The tokenId of the NFT to burn.
| _amount | uint256 | The amount of the NFT to burn.

### burnBatch

```solidity
function burnBatch(address _owner, uint256[] _tokenIds, uint256[] _amounts) external nonpayable
```

Lets an owner or approved operator burn NFTs of the given tokenIds.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _owner | address | The owner of the NFTs to burn.
| _tokenIds | uint256[] | The tokenIds of the NFTs to burn.
| _amounts | uint256[] | The amounts of the NFTs to burn.

### contractURI

```solidity
function contractURI() external view returns (string)
```

Returns the contract metadata URI.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined

### encryptDecrypt

```solidity
function encryptDecrypt(bytes data, bytes key) external pure returns (bytes result)
```

Encrypt/decrypt data on chain.

*Encrypt/decrypt given `data` with `key`. Uses inline assembly.                  See: https://ethereum.stackexchange.com/questions/69825/decrypt-message-on-chain*

#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes | Bytes of data to encrypt/decrypt.
| key | bytes | Secure key used by caller for encryption/decryption.

#### Returns

| Name | Type | Description |
|---|---|---|
| result | bytes |  Output after encryption/decryption of given data.

### encryptedBaseURI

```solidity
function encryptedBaseURI(uint256) external view returns (bytes)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined

### getBaseURICount

```solidity
function getBaseURICount() external view returns (uint256)
```

Returns the count of batches of NFTs.

*Each batch of tokens has an in ID and an associated `baseURI`.                  See {batchIds}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### getBatchIdAtIndex

```solidity
function getBatchIdAtIndex(uint256 _index) external view returns (uint256)
```

Returns the ID for the batch of tokens the given tokenId belongs to.

*See {getBaseURICount}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _index | uint256 | ID of a token.

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### getDefaultRoyaltyInfo

```solidity
function getDefaultRoyaltyInfo() external view returns (address, uint16)
```

Returns the defualt royalty recipient and BPS for this contract&#39;s NFTs.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined
| _1 | uint16 | undefined

### getRevealURI

```solidity
function getRevealURI(uint256 _batchId, bytes _key) external view returns (string revealedURI)
```

Returns revealed URI for a batch of NFTs.

*Reveal encrypted base URI for `_batchId` with caller/admin&#39;s `_key` used for encryption.                      Reverts if there&#39;s no encrypted URI for `_batchId`.                      See {encryptDecrypt}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _batchId | uint256 | ID of the batch for which URI is being revealed.
| _key | bytes | Secure key used by caller/admin for encryption of baseURI.

#### Returns

| Name | Type | Description |
|---|---|---|
| revealedURI | string | Decrypted base URI.

### getRoyaltyInfoForToken

```solidity
function getRoyaltyInfoForToken(uint256 _tokenId) external view returns (address, uint16)
```

View royalty info for a given token.

*Returns royalty recipient and bps for `_tokenId`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | The tokenID of the NFT for which to query royalty info.

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

### isEncryptedBatch

```solidity
function isEncryptedBatch(uint256 _batchId) external view returns (bool)
```

Returns whether the relvant batch of NFTs is subject to a delayed reveal.

*Returns `true` if `_batchId`&#39;s base URI is encrypted.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _batchId | uint256 | ID of a batch of NFTs.

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### lazyMint

```solidity
function lazyMint(uint256 _amount, string _baseURIForTokens, bytes _encryptedBaseURI) external nonpayable returns (uint256 batchId)
```

Lets an authorized address lazy mint a given amount of NFTs.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | The number of NFTs to lazy mint.
| _baseURIForTokens | string | The placeholder base URI for the &#39;n&#39; number of NFTs being lazy minted, where the                           metadata for each of those NFTs is `${baseURIForTokens}/${tokenId}`.
| _encryptedBaseURI | bytes | The encrypted base URI for the batch of NFTs being lazy minted.

#### Returns

| Name | Type | Description |
|---|---|---|
| batchId | uint256 |          A unique integer identifier for the batch of NFTs lazy minted together.

### mintTo

```solidity
function mintTo(address _to, uint256 _tokenId, string, uint256 _amount) external nonpayable
```

Lets an authorized address mint lazy minted NFTs to a recipient.

*- The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _to | address | The recipient of the NFTs to mint.
| _tokenId | uint256 | The tokenId of the lazy minted NFT to mint.
| _2 | string | undefined
| _amount | uint256 | The amount of the same NFT to mint.

### multicall

```solidity
function multicall(bytes[] data) external nonpayable returns (bytes[] results)
```

Receives and executes a batch of function calls on this contract.

*Receives and executes a batch of function calls on this contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes[] | The bytes data that makes up the batch of function calls to execute.

#### Returns

| Name | Type | Description |
|---|---|---|
| results | bytes[] | The bytes data that makes up the result of the batch of function calls executed.

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

The tokenId assigned to the next new NFT to be lazy minted.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### owner

```solidity
function owner() external view returns (address)
```

Returns the owner of the contract.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

### reveal

```solidity
function reveal(uint256 _index, bytes _key) external nonpayable returns (string revealedURI)
```

Lets an authorized address reveal a batch of delayed reveal NFTs.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _index | uint256 | The ID for the batch of delayed-reveal NFTs to reveal.
| _key | bytes | The key with which the base URI for the relevant batch of NFTs was encrypted.

#### Returns

| Name | Type | Description |
|---|---|---|
| revealedURI | string | undefined

### royaltyInfo

```solidity
function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount)
```

View royalty info for a given token and sale price.

*Returns royalty amount and recipient for `tokenId` and `salePrice`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | The tokenID of the NFT for which to query royalty info.
| salePrice | uint256 | Sale price of the token.

#### Returns

| Name | Type | Description |
|---|---|---|
| receiver | address |        Address of royalty recipient account.
| royaltyAmount | uint256 |   Royalty amount calculated at current royaltyBps value.

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

Lets a contract admin set the URI for contract-level metadata.

*Caller should be authorized to setup contractURI, e.g. contract admin.                  See {_canSetContractURI}.                  Emits {ContractURIUpdated Event}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _uri | string | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;)

### setDefaultRoyaltyInfo

```solidity
function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external nonpayable
```

Updates default royalty recipient and bps.

*Caller should be authorized to set royalty info.                  See {_canSetRoyaltyInfo}.                  Emits {DefaultRoyalty Event}; See {_setupDefaultRoyaltyInfo}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _royaltyRecipient | address | Address to be set as default royalty recipient.
| _royaltyBps | uint256 | Updated royalty bps.

### setOwner

```solidity
function setOwner(address _newOwner) external nonpayable
```

Lets an authorized wallet set a new owner for the contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _newOwner | address | The address to set as the new owner of the contract.

### setRoyaltyInfoForToken

```solidity
function setRoyaltyInfoForToken(uint256 _tokenId, address _recipient, uint256 _bps) external nonpayable
```

Updates default royalty recipient and bps for a particular token.

*Sets royalty info for `_tokenId`. Caller should be authorized to set royalty info.                  See {_canSetRoyaltyInfo}.                  Emits {RoyaltyForToken Event}; See {_setupRoyaltyInfoForToken}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined
| _recipient | address | Address to be set as royalty recipient for given token Id.
| _bps | uint256 | Updated royalty bps for the token Id.

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

### uri

```solidity
function uri(uint256 _tokenId) external view returns (string)
```

Returns the metadata URI for an NFT.

*See `BatchMintMetadata` for handling of metadata in this contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | The tokenId of an NFT.

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

### TokenURIRevealed

```solidity
event TokenURIRevealed(uint256 indexed index, string revealedURI)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| index `indexed` | uint256 | undefined |
| revealedURI  | string | undefined |

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



