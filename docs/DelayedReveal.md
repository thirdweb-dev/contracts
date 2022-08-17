# DelayedReveal



> Delayed Reveal

Thirdweb&#39;s `DelayedReveal` is a contract extension for base NFT contracts. It lets you create batches of           &#39;delayed-reveal&#39; NFTs. You can learn more about the usage of delayed reveal NFTs here - https://blog.thirdweb.com/delayed-reveal-nfts



## Methods

### encryptDecrypt

```solidity
function encryptDecrypt(bytes data, bytes key) external pure returns (bytes result)
```

Encrypt/decrypt data on chain.

*Encrypt/decrypt given `data` with `key`. Uses inline assembly.                  See: https://ethereum.stackexchange.com/questions/69825/decrypt-message-on-chain*

#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes | Bytes of data to encrypt/decrypt. |
| key | bytes | Secure key used by caller for encryption/decryption. |

#### Returns

| Name | Type | Description |
|---|---|---|
| result | bytes |  Output after encryption/decryption of given data. |

### encryptedData

```solidity
function encryptedData(uint256) external view returns (bytes)
```



*Mapping from tokenId of a batch of tokens =&gt; to delayed reveal data.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

### getRevealURI

```solidity
function getRevealURI(uint256 _batchId, bytes _key) external view returns (string revealedURI)
```

Returns revealed URI for a batch of NFTs.

*Reveal encrypted base URI for `_batchId` with caller/admin&#39;s `_key` used for encryption.                      Reverts if there&#39;s no encrypted URI for `_batchId`.                      See {encryptDecrypt}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _batchId | uint256 | ID of the batch for which URI is being revealed. |
| _key | bytes | Secure key used by caller/admin for encryption of baseURI. |

#### Returns

| Name | Type | Description |
|---|---|---|
| revealedURI | string | Decrypted base URI. |

### isEncryptedBatch

```solidity
function isEncryptedBatch(uint256 _batchId) external view returns (bool)
```

Returns whether the relvant batch of NFTs is subject to a delayed reveal.

*Returns `true` if `_batchId`&#39;s base URI is encrypted.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _batchId | uint256 | ID of a batch of NFTs. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### reveal

```solidity
function reveal(uint256 identifier, bytes key) external nonpayable returns (string revealedURI)
```

Reveals a batch of delayed reveal NFTs.



#### Parameters

| Name | Type | Description |
|---|---|---|
| identifier | uint256 | The ID for the batch of delayed-reveal NFTs to reveal. |
| key | bytes | The key with which the base URI for the relevant batch of NFTs was encrypted. |

#### Returns

| Name | Type | Description |
|---|---|---|
| revealedURI | string | undefined |



## Events

### TokenURIRevealed

```solidity
event TokenURIRevealed(uint256 indexed index, string revealedURI)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| index `indexed` | uint256 | undefined |
| revealedURI  | string | undefined |



