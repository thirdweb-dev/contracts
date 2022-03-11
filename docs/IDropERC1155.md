# IDropERC1155





Thirdweb&#39;s &#39;Drop&#39; contracts are distribution mechanisms for tokens. The  `DropERC721` contract is a distribution mechanism for ERC721 tokens.  A minter wallet (i.e. holder of `MINTER_ROLE`) can (lazy)mint &#39;n&#39; tokens  at once by providing a single base URI for all tokens being lazy minted.  The URI for each of the &#39;n&#39; tokens lazy minted is the provided base URI +  `{tokenId}` of the respective token. (e.g. &quot;ipsf://Qmece.../1&quot;).  A minter can choose to lazy mint &#39;delayed-reveal&#39; tokens. More on &#39;delayed-reveal&#39;  tokens in [this article](https://blog.thirdweb.com/delayed-reveal-nfts).  A contract admin (i.e. holder of `DEFAULT_ADMIN_ROLE`) can create claim conditions  with non-overlapping time windows, and accounts can claim the tokens according to  restrictions defined in the claim condition that is active at the time of the transaction.



## Methods

### balanceOf

```solidity
function balanceOf(address account, uint256 id) external view returns (uint256)
```



*Returns the amount of tokens of token type `id` owned by `account`. Requirements: - `account` cannot be the zero address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined
| id | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### balanceOfBatch

```solidity
function balanceOfBatch(address[] accounts, uint256[] ids) external view returns (uint256[])
```



*xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}. Requirements: - `accounts` and `ids` must have the same length.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| accounts | address[] | undefined
| ids | uint256[] | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256[] | undefined

### claim

```solidity
function claim(address receiver, uint256 tokenId, uint256 quantity, address currency, uint256 pricePerToken, bytes32[] proofs, uint256 proofMaxQuantityPerTransaction) external payable
```

Lets an account claim a given quantity of NFTs.



#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | The receiver of the NFTs to claim.
| tokenId | uint256 | The unique ID of the token to claim.
| quantity | uint256 | The quantity of NFTs to claim.
| currency | address | The currency in which to pay for the claim.
| pricePerToken | uint256 | The price per token to pay for the claim.
| proofs | bytes32[] | The proof of the claimer&#39;s inclusion in the merkle root allowlist                                        of the claim conditions that apply.
| proofMaxQuantityPerTransaction | uint256 | (Optional) The maximum number of NFTs an address included in an                                        allowlist can claim.

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

### isApprovedForAll

```solidity
function isApprovedForAll(address account, address operator) external view returns (bool)
```



*Returns true if `operator` is approved to transfer ``account``&#39;s tokens. See {setApprovalForAll}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined
| operator | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### lazyMint

```solidity
function lazyMint(uint256 amount, string baseURIForTokens) external nonpayable
```

Lets an account with `MINTER_ROLE` lazy mint &#39;n&#39; NFTs.          The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | The amount of NFTs to lazy mint.
| baseURIForTokens | string | The URI for the NFTs to lazy mint.

### owner

```solidity
function owner() external view returns (address)
```



*Returns the owner of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

### primarySaleRecipient

```solidity
function primarySaleRecipient() external view returns (address)
```



*The adress that receives all primary sales value.*


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

### safeBatchTransferFrom

```solidity
function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] amounts, bytes data) external nonpayable
```



*xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}. Emits a {TransferBatch} event. Requirements: - `ids` and `amounts` must have the same length. - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the acceptance magic value.*

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



*Transfers `amount` tokens of token type `id` from `from` to `to`. Emits a {TransferSingle} event. Requirements: - `to` cannot be the zero address. - If the caller is not `from`, it must be have been approved to spend ``from``&#39;s tokens via {setApprovalForAll}. - `from` must have a balance of tokens of type `id` of at least `amount`. - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the acceptance magic value.*

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



*Grants or revokes permission to `operator` to transfer the caller&#39;s tokens, according to `approved`, Emits an {ApprovalForAll} event. Requirements: - `operator` cannot be the caller.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | undefined
| approved | bool | undefined

### setClaimConditions

```solidity
function setClaimConditions(uint256 tokenId, IDropClaimCondition.ClaimCondition[] phases, bool resetClaimEligibility) external nonpayable
```

Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | The token ID for which to set mint conditions.
| phases | IDropClaimCondition.ClaimCondition[] | Claim conditions in ascending order by `startTimestamp`.
| resetClaimEligibility | bool | Whether to reset `limitLastClaimTimestamp` and                               `limitMerkleProofClaim` values when setting new                               claim conditions.

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

### setPrimarySaleRecipient

```solidity
function setPrimarySaleRecipient(address _saleRecipient) external nonpayable
```



*Lets a module admin set the default recipient of all primary sales.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _saleRecipient | address | undefined

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



## Events

### ApprovalForAll

```solidity
event ApprovalForAll(address indexed account, address indexed operator, bool approved)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| operator `indexed` | address | undefined |
| approved  | bool | undefined |

### ClaimConditionsUpdated

```solidity
event ClaimConditionsUpdated(uint256 indexed tokenId, IDropClaimCondition.ClaimCondition[] claimConditions)
```



*Emitted when new claim conditions are set for a token.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId `indexed` | uint256 | undefined |
| claimConditions  | IDropClaimCondition.ClaimCondition[] | undefined |

### DefaultRoyalty

```solidity
event DefaultRoyalty(address newRoyaltyRecipient, uint256 newRoyaltyBps)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newRoyaltyRecipient  | address | undefined |
| newRoyaltyBps  | uint256 | undefined |

### MaxTotalSupplyUpdated

```solidity
event MaxTotalSupplyUpdated(uint256 tokenId, uint256 maxTotalSupply)
```



*Emitted when the global max supply of a token is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId  | uint256 | undefined |
| maxTotalSupply  | uint256 | undefined |

### MaxWalletClaimCountUpdated

```solidity
event MaxWalletClaimCountUpdated(uint256 tokenId, uint256 count)
```



*Emitted when the max wallet claim count for a given tokenId is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId  | uint256 | undefined |
| count  | uint256 | undefined |

### OwnerUpdated

```solidity
event OwnerUpdated(address prevOwner, address newOwner)
```



*Emitted when a new owner is set.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| prevOwner  | address | undefined |
| newOwner  | address | undefined |

### PlatformFeeInfoUpdated

```solidity
event PlatformFeeInfoUpdated(address platformFeeRecipient, uint256 platformFeeBps)
```



*Emitted when fee platform fee recipient or bps is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| platformFeeRecipient  | address | undefined |
| platformFeeBps  | uint256 | undefined |

### PrimarySaleRecipientUpdated

```solidity
event PrimarySaleRecipientUpdated(address indexed recipient)
```



*Emitted when a new primary sale recipient is set.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| recipient `indexed` | address | undefined |

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

### TokensClaimed

```solidity
event TokensClaimed(uint256 indexed claimConditionIndex, uint256 indexed tokenId, address indexed claimer, address receiver, uint256 quantityClaimed)
```



*Emitted when tokens are claimed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| claimConditionIndex `indexed` | uint256 | undefined |
| tokenId `indexed` | uint256 | undefined |
| claimer `indexed` | address | undefined |
| receiver  | address | undefined |
| quantityClaimed  | uint256 | undefined |

### TokensLazyMinted

```solidity
event TokensLazyMinted(uint256 startTokenId, uint256 endTokenId, string baseURI)
```



*Emitted when tokens are lazy minted.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| startTokenId  | uint256 | undefined |
| endTokenId  | uint256 | undefined |
| baseURI  | string | undefined |

### TransferBatch

```solidity
event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| operator `indexed` | address | undefined |
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| ids  | uint256[] | undefined |
| values  | uint256[] | undefined |

### TransferSingle

```solidity
event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| operator `indexed` | address | undefined |
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| id  | uint256 | undefined |
| value  | uint256 | undefined |

### URI

```solidity
event URI(string value, uint256 indexed id)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| value  | string | undefined |
| id `indexed` | uint256 | undefined |

### WalletClaimCountUpdated

```solidity
event WalletClaimCountUpdated(uint256 tokenId, address indexed wallet, uint256 count)
```



*Emitted when the wallet claim count for a given tokenId and address is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId  | uint256 | undefined |
| wallet `indexed` | address | undefined |
| count  | uint256 | undefined |



