# PackVRFDirect





NOTE: This contract is a work in progress.



## Methods

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### balanceOf

```solidity
function balanceOf(address account, uint256 id) external view returns (uint256)
```



*See {IERC1155-balanceOf}. Requirements: - `account` cannot be the zero address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| id | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### balanceOfBatch

```solidity
function balanceOfBatch(address[] accounts, uint256[] ids) external view returns (uint256[])
```



*See {IERC1155-balanceOfBatch}. Requirements: - `accounts` and `ids` must have the same length.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| accounts | address[] | undefined |
| ids | uint256[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256[] | undefined |

### canClaimRewards

```solidity
function canClaimRewards(address _opener) external view returns (bool)
```

Returns whether a pack opener is ready to call `claimRewards`.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _opener | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### claimRewards

```solidity
function claimRewards() external nonpayable returns (struct ITokenBundle.Token[])
```

Lets a pack owner open packs and receive the packs&#39; reward units.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | ITokenBundle.Token[] | undefined |

### contractType

```solidity
function contractType() external pure returns (bytes32)
```



*Returns the type of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### contractURI

```solidity
function contractURI() external view returns (string)
```

Returns the contract metadata URI.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### contractVersion

```solidity
function contractVersion() external pure returns (uint8)
```



*Returns the version of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint8 | undefined |

### createPack

```solidity
function createPack(ITokenBundle.Token[] _contents, uint256[] _numOfRewardUnits, string _packUri, uint128 _openStartTimestamp, uint128 _amountDistributedPerOpen, address _recipient) external payable returns (uint256 packId, uint256 packTotalSupply)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _contents | ITokenBundle.Token[] | undefined |
| _numOfRewardUnits | uint256[] | undefined |
| _packUri | string | undefined |
| _openStartTimestamp | uint128 | undefined |
| _amountDistributedPerOpen | uint128 | undefined |
| _recipient | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| packId | uint256 | undefined |
| packTotalSupply | uint256 | undefined |

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

### getPackContents

```solidity
function getPackContents(uint256 _packId) external view returns (struct ITokenBundle.Token[] contents, uint256[] perUnitAmounts)
```



*Returns the underlying contents of a pack.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _packId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| contents | ITokenBundle.Token[] | undefined |
| perUnitAmounts | uint256[] | undefined |

### getRoleAdmin

```solidity
function getRoleAdmin(bytes32 role) external view returns (bytes32)
```

Returns the admin role that controls the specified role.

*See {grantRole} and {revokeRole}.                  To change a role&#39;s admin, use {_setRoleAdmin}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

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

### getTokenCountOfBundle

```solidity
function getTokenCountOfBundle(uint256 _bundleId) external view returns (uint256)
```



*Returns the total number of assets in a particular bundle.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _bundleId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getTokenOfBundle

```solidity
function getTokenOfBundle(uint256 _bundleId, uint256 index) external view returns (struct ITokenBundle.Token)
```



*Returns an asset contained in a particular bundle, at a particular index.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _bundleId | uint256 | undefined |
| index | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | ITokenBundle.Token | undefined |

### getUriOfBundle

```solidity
function getUriOfBundle(uint256 _bundleId) external view returns (string)
```



*Returns the uri of a particular bundle.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _bundleId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### grantRole

```solidity
function grantRole(bytes32 role, address account) external nonpayable
```

Grants a role to an account, if not previously granted.

*Caller must have admin role for the `role`.                  Emits {RoleGranted Event}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |
| account | address | Address of the account to which the role is being granted. |

### hasRole

```solidity
function hasRole(bytes32 role, address account) external view returns (bool)
```

Checks whether an account has a particular role.

*Returns `true` if `account` has been granted `role`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |
| account | address | Address of the account for which the role is being checked. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### hasRoleWithSwitch

```solidity
function hasRoleWithSwitch(bytes32 role, address account) external view returns (bool)
```

Checks whether an account has a particular role;                  role restrictions can be swtiched on and off.

*Returns `true` if `account` has been granted `role`.                  Role restrictions can be swtiched on and off:                      - If address(0) has ROLE, then the ROLE restrictions                        don&#39;t apply.                      - If address(0) does not have ROLE, then the ROLE                        restrictions will apply.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |
| account | address | Address of the account for which the role is being checked. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### initialize

```solidity
function initialize(address _defaultAdmin, string _name, string _symbol, string _contractURI, address[] _trustedForwarders, address _royaltyRecipient, uint256 _royaltyBps) external nonpayable
```



*Initiliazes the contract, like a constructor.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _defaultAdmin | address | undefined |
| _name | string | undefined |
| _symbol | string | undefined |
| _contractURI | string | undefined |
| _trustedForwarders | address[] | undefined |
| _royaltyRecipient | address | undefined |
| _royaltyBps | uint256 | undefined |

### isApprovedForAll

```solidity
function isApprovedForAll(address account, address operator) external view returns (bool)
```



*See {IERC1155-isApprovedForAll}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| operator | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isTrustedForwarder

```solidity
function isTrustedForwarder(address forwarder) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| forwarder | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### multicall

```solidity
function multicall(bytes[] data) external nonpayable returns (bytes[] results)
```



*Receives and executes a batch of function calls on this contract.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| results | bytes[] | undefined |

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



*The token Id of the next set of packs to be minted.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### onERC1155BatchReceived

```solidity
function onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) external nonpayable returns (bytes4)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256[] | undefined |
| _3 | uint256[] | undefined |
| _4 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### onERC1155Received

```solidity
function onERC1155Received(address, address, uint256, uint256, bytes) external nonpayable returns (bytes4)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256 | undefined |
| _3 | uint256 | undefined |
| _4 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) external nonpayable returns (bytes4)
```



*See {IERC721Receiver-onERC721Received}. Always returns `IERC721Receiver.onERC721Received.selector`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256 | undefined |
| _3 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### openPack

```solidity
function openPack(uint256 _packId, uint256 _amountToOpen) external nonpayable returns (uint256)
```

Lets a pack owner open packs and receive the packs&#39; reward units.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _packId | uint256 | undefined |
| _amountToOpen | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### openPackAndClaimRewards

```solidity
function openPackAndClaimRewards(uint256 _packId, uint256 _amountToOpen, uint32 _callBackGasLimit) external nonpayable returns (uint256)
```

Called by a pack opener to open a pack in a single transaction, instead of calling openPack and claimRewards separately.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _packId | uint256 | undefined |
| _amountToOpen | uint256 | undefined |
| _callBackGasLimit | uint32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### owner

```solidity
function owner() external view returns (address)
```

Returns the owner of the contract.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### rawFulfillRandomWords

```solidity
function rawFulfillRandomWords(uint256 _requestId, uint256[] _randomWords) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _requestId | uint256 | undefined |
| _randomWords | uint256[] | undefined |

### renounceRole

```solidity
function renounceRole(bytes32 role, address account) external nonpayable
```

Revokes role from the account.

*Caller must have the `role`, with caller being the same as `account`.                  Emits {RoleRevoked Event}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |
| account | address | Address of the account from which the role is being revoked. |

### revokeRole

```solidity
function revokeRole(bytes32 role, address account) external nonpayable
```

Revokes role from an account.

*Caller must have admin role for the `role`.                  Emits {RoleRevoked Event}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |
| account | address | Address of the account from which the role is being revoked. |

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

### sendRewardsIndirect

```solidity
function sendRewardsIndirect(address _opener) external nonpayable
```

Lets a pack owner open packs and receive the packs&#39; reward units.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _opener | address | undefined |

### setApprovalForAll

```solidity
function setApprovalForAll(address operator, bool approved) external nonpayable
```



*See {IERC1155-setApprovalForAll}.*

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

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```



*See ERC 165*

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



*Mapping from token ID =&gt; total circulating supply of token with that ID.*

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



*Returns the URI for a given tokenId.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |



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

### Initialized

```solidity
event Initialized(uint8 version)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### OwnerUpdated

```solidity
event OwnerUpdated(address indexed prevOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prevOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

### PackCreated

```solidity
event PackCreated(uint256 indexed packId, address recipient, uint256 totalPacksCreated)
```

Emitted when a set of packs is created.



#### Parameters

| Name | Type | Description |
|---|---|---|
| packId `indexed` | uint256 | undefined |
| recipient  | address | undefined |
| totalPacksCreated  | uint256 | undefined |

### PackOpenRequested

```solidity
event PackOpenRequested(address indexed opener, uint256 indexed packId, uint256 amountToOpen, uint256 requestId)
```

Emitted when the opening of a pack is requested.



#### Parameters

| Name | Type | Description |
|---|---|---|
| opener `indexed` | address | undefined |
| packId `indexed` | uint256 | undefined |
| amountToOpen  | uint256 | undefined |
| requestId  | uint256 | undefined |

### PackOpened

```solidity
event PackOpened(uint256 indexed packId, address indexed opener, uint256 numOfPacksOpened, ITokenBundle.Token[] rewardUnitsDistributed)
```

Emitted when a pack is opened.



#### Parameters

| Name | Type | Description |
|---|---|---|
| packId `indexed` | uint256 | undefined |
| opener `indexed` | address | undefined |
| numOfPacksOpened  | uint256 | undefined |
| rewardUnitsDistributed  | ITokenBundle.Token[] | undefined |

### PackRandomnessFulfilled

```solidity
event PackRandomnessFulfilled(uint256 indexed packId, uint256 indexed requestId)
```

Emitted when Chainlink VRF fulfills a random number request.



#### Parameters

| Name | Type | Description |
|---|---|---|
| packId `indexed` | uint256 | undefined |
| requestId `indexed` | uint256 | undefined |

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



