# DelayedReveal









## Methods

### encryptDecrypt

```solidity
function encryptDecrypt(bytes data, bytes key) external pure returns (bytes result)
```



*See: https://ethereum.stackexchange.com/questions/69825/decrypt-message-on-chain*

#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes | undefined
| key | bytes | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| result | bytes | undefined

### getRevealURI

```solidity
function getRevealURI(uint256 _batchId, bytes _key) external view returns (string revealedURI)
```



*Returns the decrypted i.e. revealed URI for a batch of tokens.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _batchId | uint256 | undefined
| _key | bytes | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| revealedURI | string | undefined

### reveal

```solidity
function reveal(uint256 identifier, bytes key) external nonpayable returns (string revealedURI)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| identifier | uint256 | undefined
| key | bytes | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| revealedURI | string | undefined




