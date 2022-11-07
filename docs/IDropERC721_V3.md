# IDropERC721_V3





Thirdweb&#39;s &#39;Drop&#39; contracts are distribution mechanisms for tokens. The  `DropERC721` contract is a distribution mechanism for ERC721 tokens.  A minter wallet (i.e. holder of `MINTER_ROLE`) can (lazy)mint &#39;n&#39; tokens  at once by providing a single base URI for all tokens being lazy minted.  The URI for each of the &#39;n&#39; tokens lazy minted is the provided base URI +  `{tokenId}` of the respective token. (e.g. &quot;ipsf://Qmece.../1&quot;).  A minter can choose to lazy mint &#39;delayed-reveal&#39; tokens. More on &#39;delayed-reveal&#39;  tokens in [this article](https://blog.thirdweb.com/delayed-reveal-nfts).  A contract admin (i.e. holder of `DEFAULT_ADMIN_ROLE`) can create claim conditions  with non-overlapping time windows, and accounts can claim the tokens according to  restrictions defined in the claim condition that is active at the time of the transaction.



## Methods

### approve

```solidity
function approve(address to, uint256 tokenId) external nonpayable
```



*Gives permission to `to` to transfer `tokenId` token to another account. The approval is cleared when the token is transferred. Only a single account can be approved at a time, so approving the zero address clears previous approvals. Requirements: - The caller must own the token or be an approved operator. - `tokenId` must exist. Emits an {Approval} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | undefined |
| tokenId | uint256 | undefined |

### balanceOf

```solidity
function balanceOf(address owner) external view returns (uint256 balance)
```



*Returns the number of tokens in ``owner``&#39;s account.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| balance | uint256 | undefined |

### claim

```solidity
function claim(address receiver, uint256 quantity, address currency, uint256 pricePerToken, bytes32[] proofs, uint256 proofMaxQuantityPerTransaction) external payable
```

Lets an account claim a given quantity of NFTs.



#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | The receiver of the NFTs to claim. |
| quantity | uint256 | The quantity of NFTs to claim. |
| currency | address | The currency in which to pay for the claim. |
| pricePerToken | uint256 | The price per token to pay for the claim. |
| proofs | bytes32[] | The proof of the claimer&#39;s inclusion in the merkle root allowlist                                        of the claim conditions that apply. |
| proofMaxQuantityPerTransaction | uint256 | (Optional) The maximum number of NFTs an address included in an                                        allowlist can claim. |

### getApproved

```solidity
function getApproved(uint256 tokenId) external view returns (address operator)
```



*Returns the account approved for `tokenId` token. Requirements: - `tokenId` must exist.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| operator | address | undefined |

### isApprovedForAll

```solidity
function isApprovedForAll(address owner, address operator) external view returns (bool)
```



*Returns if the `operator` is allowed to manage all of the assets of `owner`. See {setApprovalForAll}*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |
| operator | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### lazyMint

```solidity
function lazyMint(uint256 amount, string baseURIForTokens, bytes encryptedBaseURI) external nonpayable
```

Lets an account with `MINTER_ROLE` lazy mint &#39;n&#39; NFTs.          The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | The amount of NFTs to lazy mint. |
| baseURIForTokens | string | The URI for the NFTs to lazy mint. If lazy minting                           &#39;delayed-reveal&#39; NFTs, the is a URI for NFTs in the                           un-revealed state. |
| encryptedBaseURI | bytes | If lazy minting &#39;delayed-reveal&#39; NFTs, this is the                           result of encrypting the URI of the NFTs in the revealed                           state. |

### ownerOf

```solidity
function ownerOf(uint256 tokenId) external view returns (address owner)
```



*Returns the owner of the `tokenId` token. Requirements: - `tokenId` must exist.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |

### safeTransferFrom

```solidity
function safeTransferFrom(address from, address to, uint256 tokenId) external nonpayable
```



*Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients are aware of the ERC721 protocol to prevent tokens from being forever locked. Requirements: - `from` cannot be the zero address. - `to` cannot be the zero address. - `tokenId` token must exist and be owned by `from`. - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}. - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer. Emits a {Transfer} event.*

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



*Safely transfers `tokenId` token from `from` to `to`. Requirements: - `from` cannot be the zero address. - `to` cannot be the zero address. - `tokenId` token must exist and be owned by `from`. - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}. - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer. Emits a {Transfer} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| tokenId | uint256 | undefined |
| data | bytes | undefined |

### setApprovalForAll

```solidity
function setApprovalForAll(address operator, bool _approved) external nonpayable
```



*Approve or remove `operator` as an operator for the caller. Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller. Requirements: - The `operator` cannot be the caller. Emits an {ApprovalForAll} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | undefined |
| _approved | bool | undefined |

### setClaimConditions

```solidity
function setClaimConditions(IDropClaimCondition_V2.ClaimCondition[] phases, bool resetClaimEligibility) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| phases | IDropClaimCondition_V2.ClaimCondition[] | undefined |
| resetClaimEligibility | bool | undefined |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```



*Returns true if this contract implements the interface defined by `interfaceId`. See the corresponding https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section] to learn more about how these ids are created. This function call must use less than 30 000 gas.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| interfaceId | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 tokenId) external nonpayable
```



*Transfers `tokenId` token from `from` to `to`. WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible. Requirements: - `from` cannot be the zero address. - `to` cannot be the zero address. - `tokenId` token must be owned by `from`. - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}. Emits a {Transfer} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| tokenId | uint256 | undefined |



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

### ClaimConditionsUpdated

```solidity
event ClaimConditionsUpdated(IDropClaimCondition_V2.ClaimCondition[] claimConditions)
```



*Emitted when new claim conditions are set.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| claimConditions  | IDropClaimCondition_V2.ClaimCondition[] | undefined |

### MaxTotalSupplyUpdated

```solidity
event MaxTotalSupplyUpdated(uint256 maxTotalSupply)
```



*Emitted when the global max supply of tokens is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| maxTotalSupply  | uint256 | undefined |

### MaxWalletClaimCountUpdated

```solidity
event MaxWalletClaimCountUpdated(uint256 count)
```



*Emitted when the global max wallet claim count is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| count  | uint256 | undefined |

### NFTRevealed

```solidity
event NFTRevealed(uint256 endTokenId, string revealedURI)
```



*Emitted when the URI for a batch of &#39;delayed-reveal&#39; NFTs is revealed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| endTokenId  | uint256 | undefined |
| revealedURI  | string | undefined |

### TokensClaimed

```solidity
event TokensClaimed(uint256 indexed claimConditionIndex, address indexed claimer, address indexed receiver, uint256 startTokenId, uint256 quantityClaimed)
```



*Emitted when tokens are claimed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| claimConditionIndex `indexed` | uint256 | undefined |
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| startTokenId  | uint256 | undefined |
| quantityClaimed  | uint256 | undefined |

### TokensLazyMinted

```solidity
event TokensLazyMinted(uint256 startTokenId, uint256 endTokenId, string baseURI, bytes encryptedBaseURI)
```



*Emitted when tokens are lazy minted.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| startTokenId  | uint256 | undefined |
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

### WalletClaimCountUpdated

```solidity
event WalletClaimCountUpdated(address indexed wallet, uint256 count)
```



*Emitted when the wallet claim count for an address is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| wallet `indexed` | address | undefined |
| count  | uint256 | undefined |



