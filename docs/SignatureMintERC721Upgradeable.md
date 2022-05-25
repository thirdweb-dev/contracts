# SignatureMintERC721Upgradeable









## Methods

### mintWithSignature

```solidity
function mintWithSignature(ISignatureMintERC721.MintRequest req, bytes signature) external payable
```

Mints tokens according to the provided mint request.



#### Parameters

| Name | Type | Description |
|---|---|---|
| req | ISignatureMintERC721.MintRequest | The payload / mint request.
| signature | bytes | The signature produced by an account signing the mint request.

### verify

```solidity
function verify(ISignatureMintERC721.MintRequest _req, bytes _signature) external view returns (bool success, address signer)
```



*Verifies that a mint request is signed by an account holding MINTER_ROLE (at the time of the function call).*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _req | ISignatureMintERC721.MintRequest | undefined
| _signature | bytes | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined
| signer | address | undefined




