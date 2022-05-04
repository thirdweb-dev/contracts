# IERC721



> ERC-721 Non-Fungible Token Standard



*See https://eips.ethereum.org/EIPS/eip-721  Note: the ERC-165 identifier for this interface is 0x80ac58cd.*

## Methods

### approve

```solidity
function approve(address _approved, uint256 _tokenId) external payable
```

Change or reaffirm the approved address for an NFT

*The zero address indicates there is no approved address.  Throws unless `msg.sender` is the current NFT owner, or an authorized  operator of the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _approved | address | The new approved NFT controller
| _tokenId | uint256 | The NFT to approve

### balanceOf

```solidity
function balanceOf(address _owner) external view returns (uint256)
```

Count all NFTs assigned to an owner

*NFTs assigned to the zero address are considered invalid, and this  function throws for queries about the zero address.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _owner | address | An address for whom to query the balance

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The number of NFTs owned by `_owner`, possibly zero

### getApproved

```solidity
function getApproved(uint256 _tokenId) external view returns (address)
```

Get the approved address for a single NFT

*Throws if `_tokenId` is not a valid NFT.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | The NFT to find the approved address for

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | The approved address for this NFT, or the zero address if there is none

### isApprovedForAll

```solidity
function isApprovedForAll(address _owner, address _operator) external view returns (bool)
```

Query if an address is an authorized operator for another address



#### Parameters

| Name | Type | Description |
|---|---|---|
| _owner | address | The address that owns the NFTs
| _operator | address | The address that acts on behalf of the owner

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | True if `_operator` is an approved operator for `_owner`, false otherwise

### ownerOf

```solidity
function ownerOf(uint256 _tokenId) external view returns (address)
```

Find the owner of an NFT

*NFTs assigned to zero address are considered invalid, and queries  about them do throw.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | The identifier for an NFT

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | The address of the owner of the NFT

### safeTransferFrom

```solidity
function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable
```

Transfers the ownership of an NFT from one address to another address

*Throws unless `msg.sender` is the current owner, an authorized  operator, or the approved address for this NFT. Throws if `_from` is  not the current owner. Throws if `_to` is the zero address. Throws if  `_tokenId` is not a valid NFT. When transfer is complete, this function  checks if `_to` is a smart contract (code size &gt; 0). If so, it calls  `onERC721Received` on `_to` and throws if the return value is not  `bytes4(keccak256(&quot;onERC721Received(address,address,uint256,bytes)&quot;))`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _from | address | The current owner of the NFT
| _to | address | The new owner
| _tokenId | uint256 | The NFT to transfer
| data | bytes | Additional data with no specified format, sent in call to `_to`

### setApprovalForAll

```solidity
function setApprovalForAll(address _operator, bool _approved) external nonpayable
```

Enable or disable approval for a third party (&quot;operator&quot;) to manage  all of `msg.sender`&#39;s assets

*Emits the ApprovalForAll event. The contract MUST allow  multiple operators per owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _operator | address | Address to add to the set of authorized operators
| _approved | bool | True if the operator is approved, false to revoke approval

### transferFrom

```solidity
function transferFrom(address _from, address _to, uint256 _tokenId) external payable
```

Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE  THEY MAY BE PERMANENTLY LOST

*Throws unless `msg.sender` is the current owner, an authorized  operator, or the approved address for this NFT. Throws if `_from` is  not the current owner. Throws if `_to` is the zero address. Throws if  `_tokenId` is not a valid NFT.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _from | address | The current owner of the NFT
| _to | address | The new owner
| _tokenId | uint256 | The NFT to transfer



## Events

### Approval

```solidity
event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId)
```



*This emits when the approved address for an NFT is changed or  reaffirmed. The zero address indicates there is no approved address.  When a Transfer event emits, this also indicates that the approved  address for that NFT (if any) is reset to none.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _owner `indexed` | address | undefined |
| _approved `indexed` | address | undefined |
| _tokenId `indexed` | uint256 | undefined |

### ApprovalForAll

```solidity
event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved)
```



*This emits when an operator is enabled or disabled for an owner.  The operator can manage all NFTs of the owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _owner `indexed` | address | undefined |
| _operator `indexed` | address | undefined |
| _approved  | bool | undefined |

### Transfer

```solidity
event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId)
```



*This emits when ownership of any NFT changes by any mechanism.  This event emits when NFTs are created (`from` == 0) and destroyed  (`to` == 0). Exception: during contract creation, any number of NFTs  may be created and assigned without emitting Transfer. At the time of  any transfer, the approved address for that NFT (if any) is reset to none.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _from `indexed` | address | undefined |
| _to `indexed` | address | undefined |
| _tokenId `indexed` | uint256 | undefined |



