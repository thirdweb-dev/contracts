# ITokenERC1155





`SignatureMint1155` is an ERC 1155 contract. It lets anyone mint NFTs by producing a mint request  and a signature (produced by an account with MINTER_ROLE, signing the mint request).



## Methods

### balanceOf

```solidity
function balanceOf(address account, uint256 id) external view returns (uint256)
```



*Returns the amount of tokens of token type `id` owned by `account`. Requirements: - `account` cannot be the zero address.*

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



*xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}. Requirements: - `accounts` and `ids` must have the same length.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| accounts | address[] | undefined |
| ids | uint256[] | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256[] | undefined |

### isApprovedForAll

```solidity
function isApprovedForAll(address account, address operator) external view returns (bool)
```



*Returns true if `operator` is approved to transfer ``account``&#39;s tokens. See {setApprovalForAll}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| operator | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### mintTo

```solidity
function mintTo(address to, uint256 tokenId, string uri, uint256 amount) external nonpayable
```

Lets an account with MINTER_ROLE mint an NFT.



#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | The address to mint the NFT to. |
| tokenId | uint256 | The tokenId of the NFTs to mint |
| uri | string | The URI to assign to the NFT. |
| amount | uint256 | The number of copies of the NFT to mint. |

### mintWithSignature

```solidity
function mintWithSignature(ITokenERC1155.MintRequest req, bytes signature) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| req | ITokenERC1155.MintRequest | undefined |
| signature | bytes | undefined |

### safeBatchTransferFrom

```solidity
function safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] amounts, bytes data) external nonpayable
```



*xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}. Emits a {TransferBatch} event. Requirements: - `ids` and `amounts` must have the same length. - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the acceptance magic value.*

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



*Transfers `amount` tokens of token type `id` from `from` to `to`. Emits a {TransferSingle} event. Requirements: - `to` cannot be the zero address. - If the caller is not `from`, it must have been approved to spend ``from``&#39;s tokens via {setApprovalForAll}. - `from` must have a balance of tokens of type `id` of at least `amount`. - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the acceptance magic value.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| from | address | undefined |
| to | address | undefined |
| id | uint256 | undefined |
| amount | uint256 | undefined |
| data | bytes | undefined |

### setApprovalForAll

```solidity
function setApprovalForAll(address operator, bool approved) external nonpayable
```



*Grants or revokes permission to `operator` to transfer the caller&#39;s tokens, according to `approved`, Emits an {ApprovalForAll} event. Requirements: - `operator` cannot be the caller.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| operator | address | undefined |
| approved | bool | undefined |

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

### verify

```solidity
function verify(ITokenERC1155.MintRequest req, bytes signature) external view returns (bool success, address signer)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| req | ITokenERC1155.MintRequest | undefined |
| signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined |
| signer | address | undefined |



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

### TokensMinted

```solidity
event TokensMinted(address indexed mintedTo, uint256 indexed tokenIdMinted, string uri, uint256 quantityMinted)
```



*Emitted when an account with MINTER_ROLE mints an NFT.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| mintedTo `indexed` | address | undefined |
| tokenIdMinted `indexed` | uint256 | undefined |
| uri  | string | undefined |
| quantityMinted  | uint256 | undefined |

### TokensMintedWithSignature

```solidity
event TokensMintedWithSignature(address indexed signer, address indexed mintedTo, uint256 indexed tokenIdMinted, ITokenERC1155.MintRequest mintRequest)
```



*Emitted when tokens are minted.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| signer `indexed` | address | undefined |
| mintedTo `indexed` | address | undefined |
| tokenIdMinted `indexed` | uint256 | undefined |
| mintRequest  | ITokenERC1155.MintRequest | undefined |

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



