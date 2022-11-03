# DropSinglePhase1155









## Methods

### claim

```solidity
function claim(address _receiver, uint256 _tokenId, uint256 _quantity, address _currency, uint256 _pricePerToken, IDropSinglePhase1155.AllowlistProof _allowlistProof, bytes _data) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _receiver | address | undefined |
| _tokenId | uint256 | undefined |
| _quantity | uint256 | undefined |
| _currency | address | undefined |
| _pricePerToken | uint256 | undefined |
| _allowlistProof | IDropSinglePhase1155.AllowlistProof | undefined |
| _data | bytes | undefined |

### claimCondition

```solidity
function claimCondition(uint256) external view returns (uint256 startTimestamp, uint256 maxClaimableSupply, uint256 supplyClaimed, uint256 quantityLimitPerWallet, bytes32 merkleRoot, uint256 pricePerToken, address currency, string metadata)
```



*Mapping from tokenId =&gt; active claim condition for the tokenId.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| startTimestamp | uint256 | undefined |
| maxClaimableSupply | uint256 | undefined |
| supplyClaimed | uint256 | undefined |
| quantityLimitPerWallet | uint256 | undefined |
| merkleRoot | bytes32 | undefined |
| pricePerToken | uint256 | undefined |
| currency | address | undefined |
| metadata | string | undefined |

### getSupplyClaimedByWallet

```solidity
function getSupplyClaimedByWallet(uint256 _tokenId, address _claimer) external view returns (uint256)
```



*Returns the supply claimed by claimer for active conditionId.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined |
| _claimer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### setClaimConditions

```solidity
function setClaimConditions(uint256 _tokenId, IClaimCondition.ClaimCondition _condition, bool _resetClaimEligibility) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined |
| _condition | IClaimCondition.ClaimCondition | undefined |
| _resetClaimEligibility | bool | undefined |

### verifyClaim

```solidity
function verifyClaim(uint256 _tokenId, address _claimer, uint256 _quantity, address _currency, uint256 _pricePerToken, IDropSinglePhase1155.AllowlistProof _allowlistProof) external view returns (bool isOverride)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined |
| _claimer | address | undefined |
| _quantity | uint256 | undefined |
| _currency | address | undefined |
| _pricePerToken | uint256 | undefined |
| _allowlistProof | IDropSinglePhase1155.AllowlistProof | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| isOverride | bool | undefined |



## Events

### ClaimConditionUpdated

```solidity
event ClaimConditionUpdated(uint256 indexed tokenId, IClaimCondition.ClaimCondition condition, bool resetEligibility)
```

Emitted when the contract&#39;s claim conditions are updated.



#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId `indexed` | uint256 | undefined |
| condition  | IClaimCondition.ClaimCondition | undefined |
| resetEligibility  | bool | undefined |

### TokensClaimed

```solidity
event TokensClaimed(address indexed claimer, address indexed receiver, uint256 indexed tokenId, uint256 quantityClaimed)
```

Emitted when tokens are claimed via `claim`.



#### Parameters

| Name | Type | Description |
|---|---|---|
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId `indexed` | uint256 | undefined |
| quantityClaimed  | uint256 | undefined |



