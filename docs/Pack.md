# Pack









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





#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined
| ids | uint256[] | undefined
| values | uint256[] | undefined

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



*Collection level metadata.*


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

### currentRequestId

```solidity
function currentRequestId(uint256, address) external view returns (bytes32)
```



*pack tokenId =&gt; pack opener =&gt; Chainlink VRF request ID if there is an incomplete pack opening process.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined
| _1 | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined

### getDefaultRoyaltyInfo

```solidity
function getDefaultRoyaltyInfo() external view returns (address, uint16)
```



*Returns the platform fee bps and recipient.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined
| _1 | uint16 | undefined

### getPackWithRewards

```solidity
function getPackWithRewards(uint256 _packId) external view returns (struct Pack.PackState pack, uint256 packTotalSupply, address source, uint256[] tokenIds, uint256[] amountsPacked)
```



*Returns a pack with its underlying rewards*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _packId | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| pack | Pack.PackState | undefined
| packTotalSupply | uint256 | undefined
| source | address | undefined
| tokenIds | uint256[] | undefined
| amountsPacked | uint256[] | undefined

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



*Returns the royalty recipient for a particular token Id.*

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
function initialize(address _defaultAdmin, string _name, string _symbol, string _contractURI, address[] _trustedForwarders, address _royaltyRecipient, uint128 _royaltyBps, uint128 _fees, bytes32 _keyHash) external nonpayable
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
| _royaltyRecipient | address | undefined
| _royaltyBps | uint128 | undefined
| _fees | uint128 | undefined
| _keyHash | bytes32 | undefined

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

### mint

```solidity
function mint(address, uint256, uint256, bytes) external nonpayable
```



*See {ERC1155-_mint}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined
| _1 | uint256 | undefined
| _2 | uint256 | undefined
| _3 | bytes | undefined

### mintBatch

```solidity
function mintBatch(address, uint256[], uint256[], bytes) external nonpayable
```



*See {ERC1155-_mintBatch}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined
| _1 | uint256[] | undefined
| _2 | uint256[] | undefined
| _3 | bytes | undefined

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

### nextTokenId

```solidity
function nextTokenId() external view returns (uint256)
```



*The token Id of the next token to be minted.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### onERC1155BatchReceived

```solidity
function onERC1155BatchReceived(address _operator, address, uint256[] _ids, uint256[] _values, bytes _data) external nonpayable returns (bytes4)
```



*Creates pack on receiving ERC 1155 reward tokens*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _operator | address | undefined
| _1 | address | undefined
| _ids | uint256[] | undefined
| _values | uint256[] | undefined
| _data | bytes | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined

### onERC1155Received

```solidity
function onERC1155Received(address, address, uint256, uint256, bytes) external nonpayable returns (bytes4)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined
| _1 | address | undefined
| _2 | uint256 | undefined
| _3 | uint256 | undefined
| _4 | bytes | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) external nonpayable returns (bytes4)
```



*See {IERC721Receiver-onERC721Received}. Always returns `IERC721Receiver.onERC721Received.selector`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined
| _1 | address | undefined
| _2 | uint256 | undefined
| _3 | bytes | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined

### openPack

```solidity
function openPack(uint256 _packId) external nonpayable
```



*Lets a pack owner request to open a single pack.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _packId | uint256 | undefined

### owner

```solidity
function owner() external view returns (address)
```



*Returns the address of the current owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined

### packs

```solidity
function packs(uint256) external view returns (string uri, address creator, uint256 openStart)
```



*pack tokenId =&gt; The state of packs with id `tokenId`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| uri | string | undefined
| creator | address | undefined
| openStart | uint256 | undefined

### pause

```solidity
function pause() external nonpayable
```



*Pauses all token transfers. See {ERC1155Pausable} and {Pausable-_pause}. Requirements: - the caller must have the `PAUSER_ROLE`.*


### paused

```solidity
function paused() external view returns (bool)
```



*Returns true if the contract is paused, and false otherwise.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### randomnessRequests

```solidity
function randomnessRequests(bytes32) external view returns (uint256 packId, address opener)
```



*Chainlink VRF requestId =&gt; Chainlink VRF request state with id `requestId`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| packId | uint256 | undefined
| opener | address | undefined

### rawFulfillRandomness

```solidity
function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId | bytes32 | undefined
| randomness | uint256 | undefined

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

### rewards

```solidity
function rewards(uint256) external view returns (address source, uint256 rewardsPerOpen)
```



*pack tokenId =&gt; rewards in pack with id `tokenId`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| source | address | undefined
| rewardsPerOpen | uint256 | undefined

### royaltyInfo

```solidity
function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount)
```



*See EIP-2981*

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

### setChainlinkFees

```solidity
function setChainlinkFees(uint256 _newFees) external nonpayable
```



*Lets a module admin change the Chainlink VRF fee.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _newFees | uint256 | undefined

### setContractURI

```solidity
function setContractURI(string _uri) external nonpayable
```



*Sets contract URI for the storefront-level metadata of the contract.*

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
function setRoyaltyInfoForToken(uint256 _tokenId, address _recipient, uint256 _bps) external nonpayable
```



*Lets a module admin set the royalty recipient for a particular token Id.*

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



*See EIP 165*

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
function totalSupply(uint256 id) external view returns (uint256)
```



*Total amount of tokens in with a given id.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### unpause

```solidity
function unpause() external nonpayable
```



*Unpauses all token transfers. See {ERC1155Pausable} and {Pausable-_unpause}. Requirements: - the caller must have the `PAUSER_ROLE`.*


### uri

```solidity
function uri(uint256 _id) external view returns (string)
```



*See EIP 1155*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _id | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined

### withdrawLink

```solidity
function withdrawLink(address _to, uint256 _amount) external nonpayable
```



*Lets a module admin withdraw link from the contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _to | address | undefined
| _amount | uint256 | undefined



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

### PackAdded

```solidity
event PackAdded(uint256 indexed packId, address indexed rewardContract, address indexed creator, uint256 packTotalSupply, Pack.PackState packState, Pack.Rewards rewards)
```



*Emitted when a set of packs is created.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| packId `indexed` | uint256 | undefined |
| rewardContract `indexed` | address | undefined |
| creator `indexed` | address | undefined |
| packTotalSupply  | uint256 | undefined |
| packState  | Pack.PackState | undefined |
| rewards  | Pack.Rewards | undefined |

### PackOpenFulfilled

```solidity
event PackOpenFulfilled(uint256 indexed packId, address indexed opener, bytes32 requestId, address indexed rewardContract, uint256[] rewardIds)
```



*Emitted when a request to open a pack is fulfilled.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| packId `indexed` | uint256 | undefined |
| opener `indexed` | address | undefined |
| requestId  | bytes32 | undefined |
| rewardContract `indexed` | address | undefined |
| rewardIds  | uint256[] | undefined |

### PackOpenRequested

```solidity
event PackOpenRequested(uint256 indexed packId, address indexed opener, bytes32 requestId)
```



*Emitted on a request to open a pack.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| packId `indexed` | uint256 | undefined |
| opener `indexed` | address | undefined |
| requestId  | bytes32 | undefined |

### Paused

```solidity
event Paused(address account)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account  | address | undefined |

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

### Unpaused

```solidity
event Unpaused(address account)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account  | address | undefined |



