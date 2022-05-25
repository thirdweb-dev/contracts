# ISignatureMintERC721





The &#39;signature minting&#39; mechanism used in thirdweb Token smart contracts is a way for a contract admin to authorize an external party&#39;s  request to mint tokens on the admin&#39;s contract.  At a high level, this means you can authorize some external party to mint tokens on your contract, and specify what exactly will be  minted by that external party.



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
function verify(ISignatureMintERC721.MintRequest req, bytes signature) external view returns (bool success, address signer)
```

Verifies that a mint request is signed by an account holding          MINTER_ROLE (at the time of the function call).



#### Parameters

| Name | Type | Description |
|---|---|---|
| req | ISignatureMintERC721.MintRequest | The payload / mint request.
| signature | bytes | The signature produced by an account signing the mint request.  returns (success, signer) Result of verification and the recovered address.

#### Returns

| Name | Type | Description |
|---|---|---|
| success | bool | undefined
| signer | address | undefined




