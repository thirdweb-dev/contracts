# IDelayedRevealDeprecated





Thirdweb&#39;s `DelayedReveal` is a contract extension for base NFT contracts. It lets you create batches of  &#39;delayed-reveal&#39; NFTs. You can learn more about the usage of delayed reveal NFTs here - https://blog.thirdweb.com/delayed-reveal-nfts



## Methods

### encryptDecrypt

```solidity
function encryptDecrypt(bytes data, bytes key) external pure returns (bytes result)
```

Performs XOR encryption/decryption.



#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes | The data to encrypt. In the case of delayed-reveal NFTs, this is the &quot;revealed&quot; state              base URI of the relevant batch of NFTs. |
| key | bytes | The key with which to encrypt data |

#### Returns

| Name | Type | Description |
|---|---|---|
| result | bytes | undefined |

### encryptedBaseURI

```solidity
function encryptedBaseURI(uint256 identifier) external view returns (bytes)
```



*Returns the encrypted base URI associated with the given identifier.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| identifier | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

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



*Emitted when tokens are revealed.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| index `indexed` | uint256 | undefined |
| revealedURI  | string | undefined |



