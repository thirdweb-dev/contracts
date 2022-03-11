# DropERC1155









## Methods

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined

### balanceOf

```solidity
function balanceOf(address account, uint256 id) external view returns (uint256)
```



*See {IERC1155-balanceOf}. Requirements: - `account` cannot be the zero address.*

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



*See {IERC1155-balanceOfBatch}. Requirements: - `accounts` and `ids` must have the same length.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| accounts | address[] | undefined
| ids | uint256[] | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256[] | undefined

### burn

```solidity
function burn(address account, uint256 id, uint256 value) external nonpayable
```



*Lets a token owner burn the tokens they own (i.e. destroy for good)*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined
| id | uint256 | undefined
| value | uint256 | undefined

### burnBatch

```solidity
function burnBatch(address account, uint256[] ids, uint256[] values) external nonpayable
```



*Lets a token owner burn multiple tokens they own at once (i.e. destroy for good)*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined
| ids | uint256[] | undefined
| values | uint256[] | undefined

### claim

```solidity
function claim(address _receiver, uint256 _tokenId, uint256 _quantity, address _currency, uint256 _pricePerToken, bytes32[] _proofs, uint256 _proofMaxQuantityPerTransaction) external payable
```



*Lets an account claim a given quantity of NFTs, of a single tokenId.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _receiver | address | undefined
| _tokenId | uint256 | undefined
| _quantity | uint256 | undefined
| _currency | address | undefined
| _pricePerToken | uint256 | undefined
| _proofs | bytes32[] | undefined
| _proofMaxQuantityPerTransaction | uint256 | undefined

### claimCondition

```solidity
function claimCondition(uint256) external view returns (uint256 currentStartId, uint256 count)
```



*Mapping from token ID =&gt; the set of all claim conditions, at any given moment, for tokens of the token ID.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| currentStartId | uint256 | undefined
| count | uint256 | undefined

### contractType

```solidity
function contractType() external pure returns (bytes32)
```



*Returns the type of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined

### contractURI

```solidity
function contractURI() external view returns (string)
```



*Contract level metadata.*


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

### getActiveClaimConditionId

```solidity
function getActiveClaimConditionId(uint256 _tokenId) external view returns (uint256)
```



*At any given moment, returns the uid for the active claim condition, for a given tokenId.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### getClaimConditionById

```solidity
function getClaimConditionById(uint256 _tokenId, uint256 _conditionId) external view returns (struct IDropClaimCondition.ClaimCondition condition)
```



*Returns the claim condition at the given uid.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined
| _conditionId | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| condition | IDropClaimCondition.ClaimCondition | undefined

### getClaimTimestamp

```solidity
function getClaimTimestamp(uint256 _tokenId, uint256 _conditionId, address _claimer) external view returns (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp)
```



*Returns the timestamp for when a claimer is eligible for claiming NFTs again.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined
| _conditionId | uint256 | undefined
| _claimer | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| lastClaimTimestamp | uint256 | undefined
| nextValidClaimTimestamp | uint256 | undefined

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

### getPlatformFeeInfo

```solidity
function getPlatformFeeInfo() external view returns (address, uint16)
```



*Returns the platform fee recipient and bps.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined
| _1 | uint16 | undefined

### getRoleAdmin

```solidity
function getRoleAdmin(bytes32 role) external view returns (bytes32)
```



*Returns the admin role that controls `role`. See {grantRole} and {revokeRole}. To change a role&#39;s admin, use {_setRoleAdmin}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined

### getRoleMember

```solidity
function getRoleMember(bytes32 role, uint256 index) external view returns (address)
```



*Returns one of the accounts that have `role`. `index` must be a value between 0 and {getRoleMemberCount}, non-inclusive. Role bearers are not sorted in any particular way, and their ordering may change at any point. WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure you perform all queries on the same block. See the following https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post] for more information.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined
| index | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

### getRoleMemberCount

```solidity
function getRoleMemberCount(bytes32 role) external view returns (uint256)
```



*Returns the number of accounts that have `role`. Can be used together with {getRoleMember} to enumerate all bearers of a role.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

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

### grantRole

```solidity
function grantRole(bytes32 role, address account) external nonpayable
```



*Grants `role` to `account`. If `account` had not been already granted `role`, emits a {RoleGranted} event. Requirements: - the caller must have ``role``&#39;s admin role.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined
| account | address | undefined

### hasRole

```solidity
function hasRole(bytes32 role, address account) external view returns (bool)
```



*Returns `true` if `account` has been granted `role`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined
| account | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### initialize

```solidity
function initialize(address _defaultAdmin, string _name, string _symbol, string _contractURI, address[] _trustedForwarders, address _saleRecipient, address _royaltyRecipient, uint128 _royaltyBps, uint128 _platformFeeBps, address _platformFeeRecipient) external nonpayable
```



*Initiliazes the contract, like a constructor.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _defaultAdmin | address | undefined
| _name | string | undefined
| _symbol | string | undefined
| _contractURI | string | undefined
| _trustedForwarders | address[] | undefined
| _saleRecipient | address | undefined
| _royaltyRecipient | address | undefined
| _royaltyBps | uint128 | undefined
| _platformFeeBps | uint128 | undefined
| _platformFeeRecipient | address | undefined

### isApprovedForAll

```solidity
function isApprovedForAll(address account, address operator) external view returns (bool)
```



*See {IERC1155-isApprovedForAll}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined
| operator | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### isTrustedForwarder

```solidity
function isTrustedForwarder(address forwarder) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| forwarder | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### lazyMint

```solidity
function lazyMint(uint256 _amount, string _baseURIForTokens) external nonpayable
```



*Lets an account with `MINTER_ROLE` lazy mint &#39;n&#39; NFTs.       The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _amount | uint256 | undefined
| _baseURIForTokens | string | undefined

### maxTotalSupply

```solidity
function maxTotalSupply(uint256) external view returns (uint256)
```



*Mapping from token ID =&gt; maximum possible total circulating supply of tokens with that ID.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### maxWalletClaimCount

```solidity
function maxWalletClaimCount(uint256) external view returns (uint256)
```



*Mapping from token ID =&gt; the max number of NFTs of the token ID a wallet can claim.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

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



*Returns the address of the current owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

### primarySaleRecipient

```solidity
function primarySaleRecipient() external view returns (address)
```



*The address that receives all primary sales value.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

### renounceRole

```solidity
function renounceRole(bytes32 role, address account) external nonpayable
```



*Revokes `role` from the calling account. Roles are often managed via {grantRole} and {revokeRole}: this function&#39;s purpose is to provide a mechanism for accounts to lose their privileges if they are compromised (such as when a trusted device is misplaced). If the calling account had been revoked `role`, emits a {RoleRevoked} event. Requirements: - the caller must be `account`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined
| account | address | undefined

### revokeRole

```solidity
function revokeRole(bytes32 role, address account) external nonpayable
```



*Revokes `role` from `account`. If `account` had been granted `role`, emits a {RoleRevoked} event. Requirements: - the caller must have ``role``&#39;s admin role.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined
| account | address | undefined

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



*See {IERC1155-safeBatchTransferFrom}.*

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



*See {IERC1155-safeTransferFrom}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined
| to | address | undefined
| id | uint256 | undefined
| amount | uint256 | undefined
| data | bytes | undefined

### saleRecipient

```solidity
function saleRecipient(uint256) external view returns (address)
```



*Mapping from token ID =&gt; the address of the recipient of primary sales.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

### setApprovalForAll

```solidity
function setApprovalForAll(address operator, bool approved) external nonpayable
```



*See {IERC1155-setApprovalForAll}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | undefined
| approved | bool | undefined

### setClaimConditions

```solidity
function setClaimConditions(uint256 _tokenId, IDropClaimCondition.ClaimCondition[] _phases, bool _resetClaimEligibility) external nonpayable
```



*Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions, for a tokenId.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined
| _phases | IDropClaimCondition.ClaimCondition[] | undefined
| _resetClaimEligibility | bool | undefined

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

### setMaxTotalSupply

```solidity
function setMaxTotalSupply(uint256 _tokenId, uint256 _maxTotalSupply) external nonpayable
```



*Lets a module admin set a max total supply for token.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined
| _maxTotalSupply | uint256 | undefined

### setMaxWalletClaimCount

```solidity
function setMaxWalletClaimCount(uint256 _tokenId, uint256 _count) external nonpayable
```



*Lets a contract admin set a maximum number of NFTs of a tokenId that can be claimed by any wallet.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined
| _count | uint256 | undefined

### setOwner

```solidity
function setOwner(address _newOwner) external nonpayable
```



*Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _newOwner | address | undefined

### setPlatformFeeInfo

```solidity
function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external nonpayable
```



*Lets a contract admin update the platform fee recipient and bps*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _platformFeeRecipient | address | undefined
| _platformFeeBps | uint256 | undefined

### setPrimarySaleRecipient

```solidity
function setPrimarySaleRecipient(address _saleRecipient) external nonpayable
```



*Lets a contract admin set the recipient for all primary sales.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _saleRecipient | address | undefined

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

### setWalletClaimCount

```solidity
function setWalletClaimCount(uint256 _tokenId, address _claimer, uint256 _count) external nonpayable
```



*Lets a contract admin set a claim count for a wallet.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined
| _claimer | address | undefined
| _count | uint256 | undefined

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```



*See ERC 165*

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

### thirdwebFee

```solidity
function thirdwebFee() external view returns (contract ITWFee)
```



*The thirdweb contract with fee related information.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract ITWFee | undefined

### totalSupply

```solidity
function totalSupply(uint256) external view returns (uint256)
```



*Mapping from token ID =&gt; total circulating supply of tokens with that ID.*

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
function uri(uint256 _tokenId) external view returns (string _tokenURI)
```



*Returns the URI for a given tokenId.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _tokenURI | string | undefined

### verifyClaim

```solidity
function verifyClaim(uint256 _conditionId, address _claimer, uint256 _tokenId, uint256 _quantity, address _currency, uint256 _pricePerToken) external view
```



*Checks a request to claim NFTs against the active claim condition&#39;s criteria.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _conditionId | uint256 | undefined
| _claimer | address | undefined
| _tokenId | uint256 | undefined
| _quantity | uint256 | undefined
| _currency | address | undefined
| _pricePerToken | uint256 | undefined

### verifyClaimMerkleProof

```solidity
function verifyClaimMerkleProof(uint256 _conditionId, address _claimer, uint256 _tokenId, uint256 _quantity, bytes32[] _proofs, uint256 _proofMaxQuantityPerTransaction) external view returns (bool validMerkleProof, uint256 merkleProofIndex)
```



*Checks whether a claimer meets the claim condition&#39;s allowlist criteria.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _conditionId | uint256 | undefined
| _claimer | address | undefined
| _tokenId | uint256 | undefined
| _quantity | uint256 | undefined
| _proofs | bytes32[] | undefined
| _proofMaxQuantityPerTransaction | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| validMerkleProof | bool | undefined
| merkleProofIndex | uint256 | undefined

### walletClaimCount

```solidity
function walletClaimCount(uint256, address) external view returns (uint256)
```



*Mapping from token ID =&gt; claimer wallet address =&gt; total number of NFTs of the token ID a wallet has claimed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined
| _1 | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined



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





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId  | uint256 | undefined |
| maxTotalSupply  | uint256 | undefined |

### MaxWalletClaimCountUpdated

```solidity
event MaxWalletClaimCountUpdated(uint256 tokenId, uint256 count)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId  | uint256 | undefined |
| count  | uint256 | undefined |

### OwnerUpdated

```solidity
event OwnerUpdated(address prevOwner, address newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prevOwner  | address | undefined |
| newOwner  | address | undefined |

### PlatformFeeInfoUpdated

```solidity
event PlatformFeeInfoUpdated(address platformFeeRecipient, uint256 platformFeeBps)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| platformFeeRecipient  | address | undefined |
| platformFeeBps  | uint256 | undefined |

### PrimarySaleRecipientUpdated

```solidity
event PrimarySaleRecipientUpdated(address indexed recipient)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| recipient `indexed` | address | undefined |

### RoleAdminChanged

```solidity
event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| previousAdminRole `indexed` | bytes32 | undefined |
| newAdminRole `indexed` | bytes32 | undefined |

### RoleGranted

```solidity
event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| account `indexed` | address | undefined |
| sender `indexed` | address | undefined |

### RoleRevoked

```solidity
event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| account `indexed` | address | undefined |
| sender `indexed` | address | undefined |

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





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId  | uint256 | undefined |
| wallet `indexed` | address | undefined |
| count  | uint256 | undefined |



