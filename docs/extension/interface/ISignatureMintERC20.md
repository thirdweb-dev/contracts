# ISignatureMintERC20





The &#39;signature minting&#39; mechanism used in thirdweb Token smart contracts is a way for a contract admin to authorize an external party&#39;s  request to mint tokens on the admin&#39;s contract.  At a high level, this means you can authorize some external party to mint tokens on your contract, and specify what exactly will be  minted by that external party.



## Methods

### mintWithSignature

```solidity
function mintWithSignature(ISignatureMintERC20.MintRequest req, bytes signature) external payable returns (address signer)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| req | ISignatureMintERC20.MintRequest | undefined |
| signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| signer | address | undefined |

### verify

```solidity
function verify(ISignatureMintERC20.MintRequest req, bytes signature) external view returns (bool success, address signer)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| req | ISignatureMintERC20.MintRequest | undefined |
| signature | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined |
| signer | address | undefined |



## Events

### TokensMintedWithSignature

```solidity
event TokensMintedWithSignature(address indexed signer, address indexed mintedTo, ISignatureMintERC20.MintRequest mintRequest)
```



*Emitted when tokens are minted.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| signer `indexed` | address | undefined |
| mintedTo `indexed` | address | undefined |
| mintRequest  | ISignatureMintERC20.MintRequest | undefined |



