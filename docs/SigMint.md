# SigMint









## Methods

### mintWithSignature

```solidity
function mintWithSignature(ISignatureMintERC721.MintRequest _req, bytes _signature) external payable
```



*Claim lazy minted tokens via signature.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _req | ISignatureMintERC721.MintRequest | undefined
| _signature | bytes | undefined

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




