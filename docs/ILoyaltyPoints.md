# ILoyaltyPoints









## Methods

### cancel

```solidity
function cancel(address owner, uint256 amount) external nonpayable
```

Let&#39;s a loyalty pointsß owner or approved operator cancel the given amount of loyalty points.



#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |
| amount | uint256 | undefined |

### getTotalMintedInLifetime

```solidity
function getTotalMintedInLifetime(address owner) external view returns (uint256)
```

Returns the total tokens minted to `owner` in the contract&#39;s lifetime.



#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### mintTo

```solidity
function mintTo(address to, uint256 amount) external nonpayable
```

Lets an account with MINTER_ROLE mint an NFT.



#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | The address to mint tokens to. |
| amount | uint256 | The amount of tokens to mint. |

### revoke

```solidity
function revoke(address owner, uint256 amount) external nonpayable
```

Let&#39;s an approved party revoke a holder&#39;s loyalty points (no approval needed).



#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |
| amount | uint256 | undefined |



## Events

### TokensMinted

```solidity
event TokensMinted(address indexed mintedTo, uint256 quantityMinted)
```



*Emitted when an account with MINTER_ROLE mints an NFT.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| mintedTo `indexed` | address | undefined |
| quantityMinted  | uint256 | undefined |



