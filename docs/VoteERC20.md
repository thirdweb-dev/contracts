# VoteERC20









## Methods

### BALLOT_TYPEHASH

```solidity
function BALLOT_TYPEHASH() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined

### COUNTING_MODE

```solidity
function COUNTING_MODE() external pure returns (string)
```



*See {IGovernor-COUNTING_MODE}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined

### castVote

```solidity
function castVote(uint256 proposalId, uint8 support) external nonpayable returns (uint256)
```



*See {IGovernor-castVote}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| proposalId | uint256 | undefined
| support | uint8 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### castVoteBySig

```solidity
function castVoteBySig(uint256 proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s) external nonpayable returns (uint256)
```



*See {IGovernor-castVoteBySig}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| proposalId | uint256 | undefined
| support | uint8 | undefined
| v | uint8 | undefined
| r | bytes32 | undefined
| s | bytes32 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### castVoteWithReason

```solidity
function castVoteWithReason(uint256 proposalId, uint8 support, string reason) external nonpayable returns (uint256)
```



*See {IGovernor-castVoteWithReason}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| proposalId | uint256 | undefined
| support | uint8 | undefined
| reason | string | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

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

### execute

```solidity
function execute(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) external payable returns (uint256)
```



*See {IGovernor-execute}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| targets | address[] | undefined
| values | uint256[] | undefined
| calldatas | bytes[] | undefined
| descriptionHash | bytes32 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### getAllProposals

```solidity
function getAllProposals() external view returns (struct VoteERC20.Proposal[] allProposals)
```



*Returns all proposals made.*


#### Returns

| Name | Type | Description |
|---|---|---|
| allProposals | VoteERC20.Proposal[] | undefined

### getVotes

```solidity
function getVotes(address account, uint256 blockNumber) external view returns (uint256)
```

Read the voting weight from the token&#39;s built in snapshot mechanism (see {IGovernor-getVotes}).



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined
| blockNumber | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### hasVoted

```solidity
function hasVoted(uint256 proposalId, address account) external view returns (bool)
```



*See {IGovernor-hasVoted}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| proposalId | uint256 | undefined
| account | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### hashProposal

```solidity
function hashProposal(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash) external pure returns (uint256)
```



*See {IGovernor-hashProposal}. The proposal id is produced by hashing the RLC encoded `targets` array, the `values` array, the `calldatas` array and the descriptionHash (bytes32 which itself is the keccak256 hash of the description string). This proposal id can be produced from the proposal data which is part of the {ProposalCreated} event. It can even be computed in advance, before the proposal is submitted. Note that the chainId and the governor address are not part of the proposal id computation. Consequently, the same proposal (with same operation and same description) will have the same id if submitted on multiple governors accross multiple networks. This also means that in order to execute the same operation twice (on the same governor) the proposer will have to change the description in order to avoid proposal id conflicts.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| targets | address[] | undefined
| values | uint256[] | undefined
| calldatas | bytes[] | undefined
| descriptionHash | bytes32 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### initialize

```solidity
function initialize(string _name, string _contractURI, address[] _trustedForwarders, address _token, uint256 _initialVotingDelay, uint256 _initialVotingPeriod, uint256 _initialProposalThreshold, uint256 _initialVoteQuorumFraction) external nonpayable
```



*Initiliazes the contract, like a constructor.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _name | string | undefined
| _contractURI | string | undefined
| _trustedForwarders | address[] | undefined
| _token | address | undefined
| _initialVotingDelay | uint256 | undefined
| _initialVotingPeriod | uint256 | undefined
| _initialProposalThreshold | uint256 | undefined
| _initialVoteQuorumFraction | uint256 | undefined

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

### name

```solidity
function name() external view returns (string)
```



*See {IGovernor-name}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined

### onERC1155BatchReceived

```solidity
function onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) external nonpayable returns (bytes4)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined
| _1 | address | undefined
| _2 | uint256[] | undefined
| _3 | uint256[] | undefined
| _4 | bytes | undefined

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

### proposalDeadline

```solidity
function proposalDeadline(uint256 proposalId) external view returns (uint256)
```



*See {IGovernor-proposalDeadline}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| proposalId | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### proposalIndex

```solidity
function proposalIndex() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### proposalSnapshot

```solidity
function proposalSnapshot(uint256 proposalId) external view returns (uint256)
```



*See {IGovernor-proposalSnapshot}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| proposalId | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### proposalThreshold

```solidity
function proposalThreshold() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### proposalVotes

```solidity
function proposalVotes(uint256 proposalId) external view returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes)
```



*Accessor to the internal vote counts.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| proposalId | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| againstVotes | uint256 | undefined
| forVotes | uint256 | undefined
| abstainVotes | uint256 | undefined

### proposals

```solidity
function proposals(uint256) external view returns (uint256 proposalId, address proposer, uint256 startBlock, uint256 endBlock, string description)
```



*proposal index =&gt; Proposal*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| proposalId | uint256 | undefined
| proposer | address | undefined
| startBlock | uint256 | undefined
| endBlock | uint256 | undefined
| description | string | undefined

### propose

```solidity
function propose(address[] targets, uint256[] values, bytes[] calldatas, string description) external nonpayable returns (uint256 proposalId)
```



*See {IGovernor-propose}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| targets | address[] | undefined
| values | uint256[] | undefined
| calldatas | bytes[] | undefined
| description | string | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| proposalId | uint256 | undefined

### quorum

```solidity
function quorum(uint256 blockNumber) external view returns (uint256)
```



*Returns the quorum for a block number, in terms of number of votes: `supply * numerator / denominator`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| blockNumber | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### quorumDenominator

```solidity
function quorumDenominator() external view returns (uint256)
```



*Returns the quorum denominator. Defaults to 100, but may be overridden.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### quorumNumerator

```solidity
function quorumNumerator() external view returns (uint256)
```



*Returns the current quorum numerator. See {quorumDenominator}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### relay

```solidity
function relay(address target, uint256 value, bytes data) external nonpayable
```



*Relays a transaction or function call to an arbitrary target. In cases where the governance executor is some contract other than the governor itself, like when using a timelock, this function can be invoked in a governance proposal to recover tokens or Ether that was sent to the governor contract by mistake. Note that if the executor is simply the governor itself, use of `relay` is redundant.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| target | address | undefined
| value | uint256 | undefined
| data | bytes | undefined

### setContractURI

```solidity
function setContractURI(string uri) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| uri | string | undefined

### setProposalThreshold

```solidity
function setProposalThreshold(uint256 newProposalThreshold) external nonpayable
```



*Update the proposal threshold. This operation can only be performed through a governance proposal. Emits a {ProposalThresholdSet} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newProposalThreshold | uint256 | undefined

### setVotingDelay

```solidity
function setVotingDelay(uint256 newVotingDelay) external nonpayable
```



*Update the voting delay. This operation can only be performed through a governance proposal. Emits a {VotingDelaySet} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newVotingDelay | uint256 | undefined

### setVotingPeriod

```solidity
function setVotingPeriod(uint256 newVotingPeriod) external nonpayable
```



*Update the voting period. This operation can only be performed through a governance proposal. Emits a {VotingPeriodSet} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newVotingPeriod | uint256 | undefined

### state

```solidity
function state(uint256 proposalId) external view returns (enum IGovernorUpgradeable.ProposalState)
```



*See {IGovernor-state}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| proposalId | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | enum IGovernorUpgradeable.ProposalState | undefined

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

### token

```solidity
function token() external view returns (contract IVotesUpgradeable)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IVotesUpgradeable | undefined

### updateQuorumNumerator

```solidity
function updateQuorumNumerator(uint256 newQuorumNumerator) external nonpayable
```



*Changes the quorum numerator. Emits a {QuorumNumeratorUpdated} event. Requirements: - Must be called through a governance proposal. - New numerator must be smaller or equal to the denominator.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newQuorumNumerator | uint256 | undefined

### version

```solidity
function version() external view returns (string)
```



*See {IGovernor-version}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | string | undefined

### votingDelay

```solidity
function votingDelay() external view returns (uint256)
```



*See {IGovernor-votingDelay}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### votingPeriod

```solidity
function votingPeriod() external view returns (uint256)
```



*See {IGovernor-votingPeriod}.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined



## Events

### ProposalCanceled

```solidity
event ProposalCanceled(uint256 proposalId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| proposalId  | uint256 | undefined |

### ProposalCreated

```solidity
event ProposalCreated(uint256 proposalId, address proposer, address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, uint256 startBlock, uint256 endBlock, string description)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| proposalId  | uint256 | undefined |
| proposer  | address | undefined |
| targets  | address[] | undefined |
| values  | uint256[] | undefined |
| signatures  | string[] | undefined |
| calldatas  | bytes[] | undefined |
| startBlock  | uint256 | undefined |
| endBlock  | uint256 | undefined |
| description  | string | undefined |

### ProposalExecuted

```solidity
event ProposalExecuted(uint256 proposalId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| proposalId  | uint256 | undefined |

### ProposalThresholdSet

```solidity
event ProposalThresholdSet(uint256 oldProposalThreshold, uint256 newProposalThreshold)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| oldProposalThreshold  | uint256 | undefined |
| newProposalThreshold  | uint256 | undefined |

### QuorumNumeratorUpdated

```solidity
event QuorumNumeratorUpdated(uint256 oldQuorumNumerator, uint256 newQuorumNumerator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| oldQuorumNumerator  | uint256 | undefined |
| newQuorumNumerator  | uint256 | undefined |

### VoteCast

```solidity
event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| voter `indexed` | address | undefined |
| proposalId  | uint256 | undefined |
| support  | uint8 | undefined |
| weight  | uint256 | undefined |
| reason  | string | undefined |

### VotingDelaySet

```solidity
event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| oldVotingDelay  | uint256 | undefined |
| newVotingDelay  | uint256 | undefined |

### VotingPeriodSet

```solidity
event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| oldVotingPeriod  | uint256 | undefined |
| newVotingPeriod  | uint256 | undefined |



