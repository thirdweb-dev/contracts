# SignatureMintERC1155









## Methods

### mintWithSignature

```solidity
function mintWithSignature(ISignatureMintERC1155.MintRequest req, bytes signature) external payable returns (address signer)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| req | ISignatureMintERC1155.MintRequest | undefined |
| signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |

### verify

```solidity
function verify(ISignatureMintERC1155.MintRequest _req, bytes _signature) external view returns (bool success, address signer)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _req | ISignatureMintERC1155.MintRequest | undefined |
| _signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined |
| signer | address | undefined |



## Events

### TokensMintedWithSignature

```solidity
event TokensMintedWithSignature(address indexed signer, address indexed mintedTo, uint256 indexed tokenIdMinted, ISignatureMintERC1155.MintRequest mintRequest)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| signer `indexed` | address | undefined |
| mintedTo `indexed` | address | undefined |
| tokenIdMinted `indexed` | uint256 | undefined |
| mintRequest  | ISignatureMintERC1155.MintRequest | undefined |



