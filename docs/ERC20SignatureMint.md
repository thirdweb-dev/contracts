# ERC20SignatureMint









## Methods

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined

### allowance

```solidity
function allowance(address owner, address spender) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined
| spender | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### approve

```solidity
function approve(address spender, uint256 amount) external nonpayable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined
| amount | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### contractURI

```solidity
function contractURI() external view returns (string)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined

### decimals

```solidity
function decimals() external view returns (uint8)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint8 | undefined

### decreaseAllowance

```solidity
function decreaseAllowance(address spender, uint256 subtractedValue) external nonpayable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined
| subtractedValue | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### getRoleAdmin

```solidity
function getRoleAdmin(bytes32 role) external view returns (bytes32)
```



*Returns the admin role that controls `role`. See {grantRole} and {revokeRole}. To change a role&#39;s admin, use {AccessControl-_setRoleAdmin}.*

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
function getRoleMember(bytes32 role, uint256 index) external view returns (address member)
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
| member | address | undefined

### getRoleMemberCount

```solidity
function getRoleMemberCount(bytes32 role) external view returns (uint256 count)
```



*Returns the number of accounts that have `role`. Can be used together with {getRoleMember} to enumerate all bearers of a role.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| count | uint256 | undefined

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

### hasRoleWithSwitch

```solidity
function hasRoleWithSwitch(bytes32 role, address account) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined
| account | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### increaseAllowance

```solidity
function increaseAllowance(address spender, uint256 addedValue) external nonpayable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| spender | address | undefined
| addedValue | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### mint

```solidity
function mint(address _to, uint256 _amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _to | address | undefined
| _amount | uint256 | undefined

### mintWithSignature

```solidity
function mintWithSignature(ISignatureMintERC20.MintRequest _req, bytes _signature) external payable returns (address signer)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _req | ISignatureMintERC20.MintRequest | undefined
| _signature | bytes | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| signer | address | undefined

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

### renounceRole

```solidity
function renounceRole(bytes32 role, address account) external nonpayable
```



*Revokes `role` from the calling account. Roles are often managed via {grantRole} and {revokeRole}: this function&#39;s purpose is to provide a mechanism for accounts to lose their privileges if they are compromised (such as when a trusted device is misplaced). If the calling account had been granted `role`, emits a {RoleRevoked} event. Requirements: - the caller must be `account`.*

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

### setContractURI

```solidity
function setContractURI(string _uri) external nonpayable
```



*Lets a contract admin set the URI for contract-level metadata.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _uri | string | undefined

### setOwner

```solidity
function setOwner(address _newOwner) external nonpayable
```



*Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _newOwner | address | undefined

### setPrimarySaleRecipient

```solidity
function setPrimarySaleRecipient(address _saleRecipient) external nonpayable
```



*Lets a contract admin set the recipient for all primary sales.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _saleRecipient | address | undefined

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
function totalSupply() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### transfer

```solidity
function transfer(address to, uint256 amount) external nonpayable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | undefined
| amount | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 amount) external nonpayable returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined
| to | address | undefined
| amount | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### verify

```solidity
function verify(ISignatureMintERC20.MintRequest _req, bytes _signature) external view returns (bool success, address signer)
```



*Verifies that a mint request is signed by an account holding MINTER_ROLE (at the time of the function call).*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _req | ISignatureMintERC20.MintRequest | undefined
| _signature | bytes | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined
| signer | address | undefined



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

### ContractURIUpdated

```solidity
event ContractURIUpdated(string prevURI, string newURI)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prevURI  | string | undefined |
| newURI  | string | undefined |

### OwnerUpdated

```solidity
event OwnerUpdated(address indexed prevOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| prevOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

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

### TokensMintedWithSignature

```solidity
event TokensMintedWithSignature(address indexed signer, address indexed mintedTo, ISignatureMintERC20.MintRequest mintRequest)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| signer `indexed` | address | undefined |
| mintedTo `indexed` | address | undefined |
| mintRequest  | ISignatureMintERC20.MintRequest | undefined |

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


### Permissions__CanOnlyGrantToNonHolders

```solidity
error Permissions__CanOnlyGrantToNonHolders(address account)
```

Emitted when specified account already has the role.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

### Permissions__CanOnlyRenounceForSelf

```solidity
error Permissions__CanOnlyRenounceForSelf(address caller, address account)
```

Emitted when calling address is different from the specified account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| caller | address | undefined |
| account | address | undefined |

### PrimarySale__NotAuthorized

```solidity
error PrimarySale__NotAuthorized()
```



*Emitted when an unauthorized caller tries to set primary sales details.*



