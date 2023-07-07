# NonceManager





nonce management functionality



## Methods

### getNonce

```solidity
function getNonce(address sender, uint192 key) external view returns (uint256 nonce)
```

Return the next nonce for this sender. Within a given key, the nonce values are sequenced (starting with zero, and incremented by one on each userop) But UserOp with different keys can come with arbitrary order.



#### Parameters

| Name | Type | Description |
|---|---|---|
| sender | address | the account address |
| key | uint192 | the high 192 bit of the nonce |

#### Returns

| Name | Type | Description |
|---|---|---|
| nonce | uint256 | a full nonce to pass for next UserOp with this sender. |

### incrementNonce

```solidity
function incrementNonce(uint192 key) external nonpayable
```

Manually increment the nonce of the sender. This method is exposed just for completeness.. Account does NOT need to call it, neither during validation, nor elsewhere, as the EntryPoint will update the nonce regardless. Possible use-case is call it with various keys to &quot;initialize&quot; their nonces to one, so that future UserOperations will not pay extra for the first transaction with a given key.



#### Parameters

| Name | Type | Description |
|---|---|---|
| key | uint192 | undefined |

### nonceSequenceNumber

```solidity
function nonceSequenceNumber(address, uint192) external view returns (uint256)
```

The next valid sequence number for a given nonce key.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | uint192 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |




