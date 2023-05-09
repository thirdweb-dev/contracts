# DropERC20









## Methods

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### DOMAIN_SEPARATOR

```solidity
function DOMAIN_SEPARATOR() external view returns (bytes32)
```



*See {IERC20Permit-DOMAIN_SEPARATOR}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### allowance

```solidity
function allowance(address owner, address spender) external view returns (uint256)
```



*See {IERC20-allowance}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |
| spender | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### approve

```solidity
function approve(address spender, uint256 amount) external nonpayable returns (bool)
```



*See {IERC20-approve}. NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on `transferFrom`. This is semantically equivalent to an infinite approval. Requirements: - `spender` cannot be the zero address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined |
| amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```



*See {IERC20-balanceOf}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### burn

```solidity
function burn(uint256 amount) external nonpayable
```



*Destroys `amount` tokens from the caller. See {ERC20-_burn}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### burnFrom

```solidity
function burnFrom(address account, uint256 amount) external nonpayable
```



*Destroys `amount` tokens from `account`, deducting from the caller&#39;s allowance. See {ERC20-_burn} and {ERC20-allowance}. Requirements: - the caller must have allowance for ``accounts``&#39;s tokens of at least `amount`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| amount | uint256 | undefined |

### checkpoints

```solidity
function checkpoints(address account, uint32 pos) external view returns (struct ERC20VotesUpgradeable.Checkpoint)
```



*Get the `pos`-th checkpoint for `account`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| pos | uint32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | ERC20VotesUpgradeable.Checkpoint | undefined |

### claim

```solidity
function claim(address _receiver, uint256 _quantity, address _currency, uint256 _pricePerToken, IDrop.AllowlistProof _allowlistProof, bytes _data) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _receiver | address | undefined |
| _quantity | uint256 | undefined |
| _currency | address | undefined |
| _pricePerToken | uint256 | undefined |
| _allowlistProof | IDrop.AllowlistProof | undefined |
| _data | bytes | undefined |

### claimCondition

```solidity
function claimCondition() external view returns (uint256 currentStartId, uint256 count)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| currentStartId | uint256 | undefined |
| count | uint256 | undefined |

### contractType

```solidity
function contractType() external pure returns (bytes32)
```






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






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint8 | undefined |

### decimals

```solidity
function decimals() external view returns (uint8)
```



*Returns the number of decimals used to get its user representation. For example, if `decimals` equals `2`, a balance of `505` tokens should be displayed to a user as `5.05` (`505 / 10 ** 2`). Tokens usually opt for a value of 18, imitating the relationship between Ether and Wei. This is the value {ERC20} uses, unless this function is overridden; NOTE: This information is only used for _display_ purposes: it in no way affects any of the arithmetic of the contract, including {IERC20-balanceOf} and {IERC20-transfer}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint8 | undefined |

### decreaseAllowance

```solidity
function decreaseAllowance(address spender, uint256 subtractedValue) external nonpayable returns (bool)
```



*Atomically decreases the allowance granted to `spender` by the caller. This is an alternative to {approve} that can be used as a mitigation for problems described in {IERC20-approve}. Emits an {Approval} event indicating the updated allowance. Requirements: - `spender` cannot be the zero address. - `spender` must have allowance for the caller of at least `subtractedValue`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined |
| subtractedValue | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### delegate

```solidity
function delegate(address delegatee) external nonpayable
```



*Delegate votes from the sender to `delegatee`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| delegatee | address | undefined |

### delegateBySig

```solidity
function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external nonpayable
```



*Delegates votes from signer to `delegatee`*

#### Parameters

| Name | Type | Description |
|---|---|---|
| delegatee | address | undefined |
| nonce | uint256 | undefined |
| expiry | uint256 | undefined |
| v | uint8 | undefined |
| r | bytes32 | undefined |
| s | bytes32 | undefined |

### delegates

```solidity
function delegates(address account) external view returns (address)
```



*Get the address `account` is currently delegating to.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getActiveClaimConditionId

```solidity
function getActiveClaimConditionId() external view returns (uint256)
```



*At any given moment, returns the uid for the active claim condition.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getClaimConditionById

```solidity
function getClaimConditionById(uint256 _conditionId) external view returns (struct IClaimCondition.ClaimCondition condition)
```



*Returns the claim condition at the given uid.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _conditionId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| condition | IClaimCondition.ClaimCondition | undefined |

### getFlatPlatformFeeInfo

```solidity
function getFlatPlatformFeeInfo() external view returns (address, uint256)
```



*Returns the platform fee bps and recipient.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | uint256 | undefined |

### getPastTotalSupply

```solidity
function getPastTotalSupply(uint256 blockNumber) external view returns (uint256)
```



*Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances. It is but NOT the sum of all the delegated votes! Requirements: - `blockNumber` must have been already mined*

#### Parameters

| Name | Type | Description |
|---|---|---|
| blockNumber | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getPastVotes

```solidity
function getPastVotes(address account, uint256 blockNumber) external view returns (uint256)
```



*Retrieve the number of votes for `account` at the end of `blockNumber`. Requirements: - `blockNumber` must have been already mined*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| blockNumber | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getPlatformFeeInfo

```solidity
function getPlatformFeeInfo() external view returns (address, uint16)
```



*Returns the platform fee recipient and bps.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | uint16 | undefined |

### getPlatformFeeType

```solidity
function getPlatformFeeType() external view returns (enum IPlatformFee.PlatformFeeType)
```



*Returns the platform fee bps and recipient.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | enum IPlatformFee.PlatformFeeType | undefined |

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

### getRoleMember

```solidity
function getRoleMember(bytes32 role, uint256 index) external view returns (address member)
```

Returns the role-member from a list of members for a role,                  at a given index.

*Returns `member` who has `role`, at `index` of role-members list.                  See struct {RoleMembers}, and mapping {roleMembers}*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |
| index | uint256 | Index in list of current members for the role. |

#### Returns

| Name | Type | Description |
|---|---|---|
| member | address |  Address of account that has `role` |

### getRoleMemberCount

```solidity
function getRoleMemberCount(bytes32 role) external view returns (uint256 count)
```

Returns total number of accounts that have a role.

*Returns `count` of accounts that have `role`.                  See struct {RoleMembers}, and mapping {roleMembers}*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | keccak256 hash of the role. e.g. keccak256(&quot;TRANSFER_ROLE&quot;) |

#### Returns

| Name | Type | Description |
|---|---|---|
| count | uint256 |   Total number of accounts that have `role` |

### getSupplyClaimedByWallet

```solidity
function getSupplyClaimedByWallet(uint256 _conditionId, address _claimer) external view returns (uint256 supplyClaimedByWallet)
```



*Returns the supply claimed by claimer for a given conditionId.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _conditionId | uint256 | undefined |
| _claimer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| supplyClaimedByWallet | uint256 | undefined |

### getVotes

```solidity
function getVotes(address account) external view returns (uint256)
```



*Gets the current votes balance for `account`*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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

### increaseAllowance

```solidity
function increaseAllowance(address spender, uint256 addedValue) external nonpayable returns (bool)
```



*Atomically increases the allowance granted to `spender` by the caller. This is an alternative to {approve} that can be used as a mitigation for problems described in {IERC20-approve}. Emits an {Approval} event indicating the updated allowance. Requirements: - `spender` cannot be the zero address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined |
| addedValue | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### initialize

```solidity
function initialize(address _defaultAdmin, string _name, string _symbol, string _contractURI, address[] _trustedForwarders, address _saleRecipient, address _platformFeeRecipient, uint128 _platformFeeBps) external nonpayable
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
| _saleRecipient | address | undefined |
| _platformFeeRecipient | address | undefined |
| _platformFeeBps | uint128 | undefined |

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

### maxTotalSupply

```solidity
function maxTotalSupply() external view returns (uint256)
```



*Global max total supply of tokens.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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



*Returns the name of the token.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### nonces

```solidity
function nonces(address owner) external view returns (uint256)
```



*See {IERC20Permit-nonces}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### numCheckpoints

```solidity
function numCheckpoints(address account) external view returns (uint32)
```



*Get number of checkpoints for `account`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint32 | undefined |

### permit

```solidity
function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external nonpayable
```



*See {IERC20Permit-permit}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |
| spender | address | undefined |
| value | uint256 | undefined |
| deadline | uint256 | undefined |
| v | uint8 | undefined |
| r | bytes32 | undefined |
| s | bytes32 | undefined |

### primarySaleRecipient

```solidity
function primarySaleRecipient() external view returns (address)
```



*Returns primary sale recipient address.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

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

### setClaimConditions

```solidity
function setClaimConditions(IClaimCondition.ClaimCondition[] _conditions, bool _resetClaimEligibility) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _conditions | IClaimCondition.ClaimCondition[] | undefined |
| _resetClaimEligibility | bool | undefined |

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

### setFlatPlatformFeeInfo

```solidity
function setFlatPlatformFeeInfo(address _platformFeeRecipient, uint256 _flatFee) external nonpayable
```

Lets a module admin set a flat fee on primary sales.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _platformFeeRecipient | address | undefined |
| _flatFee | uint256 | undefined |

### setMaxTotalSupply

```solidity
function setMaxTotalSupply(uint256 _maxTotalSupply) external nonpayable
```



*Lets a contract admin set the global maximum supply for collection&#39;s NFTs.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _maxTotalSupply | uint256 | undefined |

### setPlatformFeeInfo

```solidity
function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external nonpayable
```

Updates the platform fee recipient and bps.

*Caller should be authorized to set platform fee info.                  See {_canSetPlatformFeeInfo}.                  Emits {PlatformFeeInfoUpdated Event}; See {_setupPlatformFeeInfo}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _platformFeeRecipient | address | Address to be set as new platformFeeRecipient. |
| _platformFeeBps | uint256 | Updated platformFeeBps. |

### setPlatformFeeType

```solidity
function setPlatformFeeType(enum IPlatformFee.PlatformFeeType _feeType) external nonpayable
```

Lets a module admin set platform fee type.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _feeType | enum IPlatformFee.PlatformFeeType | undefined |

### setPrimarySaleRecipient

```solidity
function setPrimarySaleRecipient(address _saleRecipient) external nonpayable
```

Updates primary sale recipient.

*Caller should be authorized to set primary sales info.                  See {_canSetPrimarySaleRecipient}.                  Emits {PrimarySaleRecipientUpdated Event}; See {_setupPrimarySaleRecipient}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _saleRecipient | address | Address to be set as new recipient of primary sales. |

### symbol

```solidity
function symbol() external view returns (string)
```



*Returns the symbol of the token, usually a shorter version of the name.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined |

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```



*See {IERC20-totalSupply}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### transfer

```solidity
function transfer(address to, uint256 amount) external nonpayable returns (bool)
```



*See {IERC20-transfer}. Requirements: - `to` cannot be the zero address. - the caller must have a balance of at least `amount`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | undefined |
| amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 amount) external nonpayable returns (bool)
```



*See {IERC20-transferFrom}. Emits an {Approval} event indicating the updated allowance. This is not required by the EIP. See the note at the beginning of {ERC20}. NOTE: Does not update the allowance if the current allowance is the maximum `uint256`. Requirements: - `from` and `to` cannot be the zero address. - `from` must have a balance of at least `amount`. - the caller must have allowance for ``from``&#39;s tokens of at least `amount`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### verifyClaim

```solidity
function verifyClaim(uint256 _conditionId, address _claimer, uint256 _quantity, address _currency, uint256 _pricePerToken, IDrop.AllowlistProof _allowlistProof) external view returns (bool isOverride)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _conditionId | uint256 | undefined |
| _claimer | address | undefined |
| _quantity | uint256 | undefined |
| _currency | address | undefined |
| _pricePerToken | uint256 | undefined |
| _allowlistProof | IDrop.AllowlistProof | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| isOverride | bool | undefined |



## Events

### Approval

```solidity
event Approval(address indexed owner, address indexed spender, uint256 value)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | undefined |
| spender `indexed` | address | undefined |
| value  | uint256 | undefined |

### ClaimConditionsUpdated

```solidity
event ClaimConditionsUpdated(IClaimCondition.ClaimCondition[] claimConditions, bool resetEligibility)
```

Emitted when the contract&#39;s claim conditions are updated.



#### Parameters

| Name | Type | Description |
|---|---|---|
| claimConditions  | IClaimCondition.ClaimCondition[] | undefined |
| resetEligibility  | bool | undefined |

### ContractURIUpdated

```solidity
event ContractURIUpdated(string prevURI, string newURI)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prevURI  | string | undefined |
| newURI  | string | undefined |

### DelegateChanged

```solidity
event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| delegator `indexed` | address | undefined |
| fromDelegate `indexed` | address | undefined |
| toDelegate `indexed` | address | undefined |

### DelegateVotesChanged

```solidity
event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| delegate `indexed` | address | undefined |
| previousBalance  | uint256 | undefined |
| newBalance  | uint256 | undefined |

### FlatPlatformFeeUpdated

```solidity
event FlatPlatformFeeUpdated(address platformFeeRecipient, uint256 flatFee)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| platformFeeRecipient  | address | undefined |
| flatFee  | uint256 | undefined |

### Initialized

```solidity
event Initialized(uint8 version)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### MaxTotalSupplyUpdated

```solidity
event MaxTotalSupplyUpdated(uint256 maxTotalSupply)
```



*Emitted when the global max supply of tokens is updated.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| maxTotalSupply  | uint256 | undefined |

### PlatformFeeInfoUpdated

```solidity
event PlatformFeeInfoUpdated(address indexed platformFeeRecipient, uint256 platformFeeBps)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| platformFeeRecipient `indexed` | address | undefined |
| platformFeeBps  | uint256 | undefined |

### PlatformFeeTypeUpdated

```solidity
event PlatformFeeTypeUpdated(enum IPlatformFee.PlatformFeeType feeType)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| feeType  | enum IPlatformFee.PlatformFeeType | undefined |

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

### TokensClaimed

```solidity
event TokensClaimed(uint256 indexed claimConditionIndex, address indexed claimer, address indexed receiver, uint256 startTokenId, uint256 quantityClaimed)
```

Emitted when tokens are claimed via `claim`.



#### Parameters

| Name | Type | Description |
|---|---|---|
| claimConditionIndex `indexed` | uint256 | undefined |
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| startTokenId  | uint256 | undefined |
| quantityClaimed  | uint256 | undefined |

### Transfer

```solidity
event Transfer(address indexed from, address indexed to, uint256 value)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| value  | uint256 | undefined |



