# Account





- The Account can have many Signers.  - There are two kinds of signers: `Admin`s and `Operator`s.    Each `Admin` can:      - Perform any transaction / action on this account with 1/n approval.      - Add signers or remove existing signers.      - Approve a particular smart contract call (i.e. fn signature + contract address) for an `Operator`.    Each `Operator` can:      - Perform smart contract calls it is approved for (i.e. wherever Operator =&gt; (fn signature + contract address) =&gt; TRUE).  - The Account can:      - Deploy smart contracts.      - Send native tokens.      - Call smart contracts.      - Sign messages. (EIP-1271)      - Own and transfer assets. (ERC-20/721/1155)



## Methods

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### SIGNER_ROLE

```solidity
function SIGNER_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### addAdmin

```solidity
function addAdmin(address _signer, bytes32 _accountId) external nonpayable
```

Adds an admin to the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |
| _accountId | bytes32 | undefined |

### addSigner

```solidity
function addSigner(address _signer, bytes32 _accountId) external nonpayable
```

Adds a signer to the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |
| _accountId | bytes32 | undefined |

### approveSignerForContract

```solidity
function approveSignerForContract(address _signer, address _target) external nonpayable
```

Approves a signer to be able to call any function on `_target` smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |
| _target | address | undefined |

### approveSignerForFunction

```solidity
function approveSignerForFunction(address _signer, bytes4 _selector) external nonpayable
```

Approves a signer to be able to call `_selector` function on any smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |
| _selector | bytes4 | undefined |

### approveSignerForTarget

```solidity
function approveSignerForTarget(address _signer, bytes4 _selector, address _target) external nonpayable
```

Approves a signer to be able to call `_selector` function on `_target` smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |
| _selector | bytes4 | undefined |
| _target | address | undefined |

### controller

```solidity
function controller() external view returns (address)
```

The admin smart contract of the account.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### deploy

```solidity
function deploy(bytes _bytecode, bytes32 _salt, uint256 _value) external payable returns (address deployment)
```

Deploys a smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _bytecode | bytes | undefined |
| _salt | bytes32 | undefined |
| _value | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| deployment | address | undefined |

### disapproveSignerForContract

```solidity
function disapproveSignerForContract(address _signer, address _target) external nonpayable
```

Disapproves a signer from being able to call arbitrary function on `_target` smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |
| _target | address | undefined |

### disapproveSignerForFunction

```solidity
function disapproveSignerForFunction(address _signer, bytes4 _selector) external nonpayable
```

Disapproves a signer from being able to call `_selector` function on arbitrary smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |
| _selector | bytes4 | undefined |

### disapproveSignerForTarget

```solidity
function disapproveSignerForTarget(address _signer, bytes4 _selector, address _target) external nonpayable
```

Removes approval of a signer from being able to call `_selector` function on `_target` smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |
| _selector | bytes4 | undefined |
| _target | address | undefined |

### execute

```solidity
function execute(IAccount.TransactionParams _params, bytes _signature) external payable returns (bool success)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _params | IAccount.TransactionParams | undefined |
| _signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined |

### getAllApprovedContracts

```solidity
function getAllApprovedContracts(address _signer) external view returns (address[])
```

Returns all contract targets approved for a given signer.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address[] | undefined |

### getAllApprovedFunctions

```solidity
function getAllApprovedFunctions(address _signer) external view returns (bytes4[] functions)
```

Returns all function targets approved for a given signer.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| functions | bytes4[] | undefined |

### getAllApprovedTargets

```solidity
function getAllApprovedTargets(address _signer) external view returns (struct IAccount.CallTarget[] approvedTargets)
```

Returns all call targets approved for a given signer.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| approvedTargets | IAccount.CallTarget[] | undefined |

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
function grantRole(bytes32, address) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |
| _1 | address | undefined |

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
function initialize(address[] _trustedForwarders, address _controller, address _signer) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _trustedForwarders | address[] | undefined |
| _controller | address | undefined |
| _signer | address | undefined |

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

### isValidSignature

```solidity
function isValidSignature(bytes32 _hash, bytes _signature) external view returns (bytes4)
```

See EIP-1271. Returns whether a signature is a valid signature made on behalf of this contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _hash | bytes32 | undefined |
| _signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

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

### nonce

```solidity
function nonce() external view returns (uint256)
```

The nonce of the account.




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

### removeAdmin

```solidity
function removeAdmin(address _signer, bytes32 _accountId) external nonpayable
```

Removes an admin from the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |
| _accountId | bytes32 | undefined |

### removeSigner

```solidity
function removeSigner(address _signer, bytes32 _accountId) external nonpayable
```

Removes a signer from the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _signer | address | undefined |
| _accountId | bytes32 | undefined |

### renounceRole

```solidity
function renounceRole(bytes32, address) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |
| _1 | address | undefined |

### revokeRole

```solidity
function revokeRole(bytes32, address) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |
| _1 | address | undefined |



## Events

### AdminAdded

```solidity
event AdminAdded(address signer)
```

Emitted when an admin is added to the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer  | address | undefined |

### AdminRemoved

```solidity
event AdminRemoved(address signer)
```

Emitted when an admin is removed from the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer  | address | undefined |

### ContractApprovedForSigner

```solidity
event ContractApprovedForSigner(address indexed signer, address indexed targetContract, bool approval)
```

Emitted when a signer is approved to call arbitrary function on `target` smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer `indexed` | address | undefined |
| targetContract `indexed` | address | undefined |
| approval  | bool | undefined |

### ContractDeployed

```solidity
event ContractDeployed(address indexed deployment)
```

Emitted when the wallet deploys a smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| deployment `indexed` | address | undefined |

### FunctionApprovedForSigner

```solidity
event FunctionApprovedForSigner(address indexed signer, bytes4 indexed selector, bool approval)
```

Emitted when a signer is approved to call `selector` function on arbitrary smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer `indexed` | address | undefined |
| selector `indexed` | bytes4 | undefined |
| approval  | bool | undefined |

### Initialized

```solidity
event Initialized(uint8 version)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

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

### SignerAdded

```solidity
event SignerAdded(address signer)
```

Emitted when a signer is added to the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer  | address | undefined |

### SignerRemoved

```solidity
event SignerRemoved(address signer)
```

Emitted when a signer is removed from the account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer  | address | undefined |

### TargetApprovedForSigner

```solidity
event TargetApprovedForSigner(address indexed signer, bytes4 indexed selector, address indexed target, bool isApproved)
```

Emitted when a signer is approved to call `selector` function on `target` smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer `indexed` | address | undefined |
| selector `indexed` | bytes4 | undefined |
| target `indexed` | address | undefined |
| isApproved  | bool | undefined |

### TransactionExecuted

```solidity
event TransactionExecuted(address indexed signer, address indexed target, bytes data, uint256 indexed nonce, uint256 value, uint256 gas)
```

Emitted when a wallet performs a call.



#### Parameters

| Name | Type | Description |
|---|---|---|
| signer `indexed` | address | undefined |
| target `indexed` | address | undefined |
| data  | bytes | undefined |
| nonce `indexed` | uint256 | undefined |
| value  | uint256 | undefined |
| gas  | uint256 | undefined |



