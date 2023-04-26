# AirdropERC1155









## Methods

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### addRecipients

```solidity
function addRecipients(IAirdropERC1155.AirdropContent[] _contents) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _contents | IAirdropERC1155.AirdropContent[] | undefined |

### airdrop

```solidity
function airdrop(IAirdropERC1155.AirdropContent[] _contents) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _contents | IAirdropERC1155.AirdropContent[] | undefined |

### cancelPendingPayments

```solidity
function cancelPendingPayments(uint256 numberOfPaymentsToCancel) external nonpayable
```

Lets contract-owner cancel any pending payments.



#### Parameters

| Name | Type | Description |
|---|---|---|
| numberOfPaymentsToCancel | uint256 | undefined |

### cancelledPaymentIndices

```solidity
function cancelledPaymentIndices(uint256) external view returns (uint256 startIndex, uint256 endIndex)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| startIndex | uint256 | undefined |
| endIndex | uint256 | undefined |

### contractType

```solidity
function contractType() external pure returns (bytes32)
```



*Returns the type of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### contractVersion

```solidity
function contractVersion() external pure returns (uint8)
```



*Returns the version of the contract.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint8 | undefined |

### getAllAirdropPayments

```solidity
function getAllAirdropPayments(uint256 startId, uint256 endId) external view returns (struct IAirdropERC1155.AirdropContent[] contents)
```

Returns all airdrop payments set up -- pending, processed or failed.



#### Parameters

| Name | Type | Description |
|---|---|---|
| startId | uint256 | undefined |
| endId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| contents | IAirdropERC1155.AirdropContent[] | undefined |

### getAllAirdropPaymentsFailed

```solidity
function getAllAirdropPaymentsFailed() external view returns (struct IAirdropERC1155.AirdropContent[] contents)
```

Returns all pending airdrop failed.




#### Returns

| Name | Type | Description |
|---|---|---|
| contents | IAirdropERC1155.AirdropContent[] | undefined |

### getAllAirdropPaymentsPending

```solidity
function getAllAirdropPaymentsPending(uint256 startId, uint256 endId) external view returns (struct IAirdropERC1155.AirdropContent[] contents)
```

Returns all pending airdrop payments.



#### Parameters

| Name | Type | Description |
|---|---|---|
| startId | uint256 | undefined |
| endId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| contents | IAirdropERC1155.AirdropContent[] | undefined |

### getCancelledPaymentIndices

```solidity
function getCancelledPaymentIndices() external view returns (struct IAirdropERC1155.CancelledPayments[])
```

Returns all blocks of cancelled payments as an array of index range.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | IAirdropERC1155.CancelledPayments[] | undefined |

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

### indicesOfFailed

```solidity
function indicesOfFailed(uint256) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### initialize

```solidity
function initialize(address _defaultAdmin) external nonpayable
```



*Initiliazes the contract, like a constructor.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _defaultAdmin | address | undefined |

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

### owner

```solidity
function owner() external view returns (address)
```

Returns the owner of the contract.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### payeeCount

```solidity
function payeeCount() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### processPayments

```solidity
function processPayments(uint256 paymentsToProcess) external nonpayable
```

Lets contract-owner send ERC721 NFTs to a list of addresses.



#### Parameters

| Name | Type | Description |
|---|---|---|
| paymentsToProcess | uint256 | undefined |

### processedCount

```solidity
function processedCount() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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

### setOwner

```solidity
function setOwner(address _newOwner) external nonpayable
```

Lets an authorized wallet set a new owner for the contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _newOwner | address | The address to set as the new owner of the contract. |



## Events

### AirdropPayment

```solidity
event AirdropPayment(address indexed recipient, uint256 index, bool failed)
```

Emitted when an airdrop payment is made to a recipient.



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipient `indexed` | address | undefined |
| index  | uint256 | undefined |
| failed  | bool | undefined |

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

### PaymentsCancelledByAdmin

```solidity
event PaymentsCancelledByAdmin(uint256 startIndex, uint256 endIndex)
```

Emitted when pending payments are cancelled, and processed count is reset.



#### Parameters

| Name | Type | Description |
|---|---|---|
| startIndex  | uint256 | undefined |
| endIndex  | uint256 | undefined |

### RecipientsAdded

```solidity
event RecipientsAdded(uint256 startIndex, uint256 endIndex)
```

Emitted when airdrop recipients are uploaded to the contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| startIndex  | uint256 | undefined |
| endIndex  | uint256 | undefined |

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

### StatelessAirdrop

```solidity
event StatelessAirdrop(address indexed recipient, IAirdropERC1155.AirdropContent content, bool failed)
```

Emitted when an airdrop is made using the stateless airdrop function.



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipient `indexed` | address | undefined |
| content  | IAirdropERC1155.AirdropContent | undefined |
| failed  | bool | undefined |



