# IDelayedRevealCommitHash





Thirdweb&#39;s `DelayedRevealCommitHash` is a contract extension for base NFT contracts. It lets you create batches of  &#39;delayed-reveal&#39; NFTs by (1) first publishing the provenance hash of the NFTs&#39; metadata URI, and later (2) publishing  the metadata URI of the NFTs which is checked against the provenance hash.



## Methods

### baseURICommitHash

```solidity
function baseURICommitHash(uint256 identifier) external view returns (bytes32)
```

Returns the provenance hash of NFTs grouped by the given identifier.



#### Parameters

| Name | Type | Description |
|---|---|---|
| identifier | uint256 | The identifier by which the relevant NFTs are grouped.

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined

### isValidBaseURI

```solidity
function isValidBaseURI(uint256 identifier, bytes32 salt, string baseURIToReveal) external view returns (bool)
```

Returns whether the given metadata URI is the true metadata URI associated with the provenance hash          for NFTs grouped by the given identifier.



#### Parameters

| Name | Type | Description |
|---|---|---|
| identifier | uint256 | The identifier by which the relevant NFTs are grouped.
| salt | bytes32 | The salt used to arrive at the relevant provenance hash.
| baseURIToReveal | string | The metadata URI of the relevant NFTs checked against the relevant provenance hash.

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined

### reveal

```solidity
function reveal(uint256 identifier, bytes32 salt, string baseURIToReveal) external nonpayable
```

Reveals a batch of delayed reveal NFTs grouped by the given identifier.



#### Parameters

| Name | Type | Description |
|---|---|---|
| identifier | uint256 | The identifier by which the relevant NFTs are grouped.
| salt | bytes32 | The salt used to arrive at the relevant provenance hash.
| baseURIToReveal | string | The metadata URI of the relevant NFTs checked against the relevant provenance hash.



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



