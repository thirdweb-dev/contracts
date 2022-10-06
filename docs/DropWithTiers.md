# DropWithTiers









## Methods

### claim

```solidity
function claim(address _receiver, uint256 _quantity, address _currency, uint256 _pricePerToken, IDropWithTiers.AllowlistProof _allowlistProof, bytes _data) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _receiver | address | undefined |
| _quantity | uint256 | undefined |
| _currency | address | undefined |
| _pricePerToken | uint256 | undefined |
| _allowlistProof | IDropWithTiers.AllowlistProof | undefined |
| _data | bytes | undefined |

### getSupplyClaimedByWallet

```solidity
function getSupplyClaimedByWallet(address _claimer, string _tier) external view returns (uint256)
```



*Returns the supply claimed by claimer for active conditionId.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _claimer | address | undefined |
| _tier | string | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### setClaimConditions

```solidity
function setClaimConditions(IDropWithTiers.ClaimConditionForTier _conditionForTier, bool _resetClaimEligibility) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _conditionForTier | IDropWithTiers.ClaimConditionForTier | undefined |
| _resetClaimEligibility | bool | undefined |

### verifyClaim

```solidity
function verifyClaim(address _claimer, uint256 _quantity, address _currency, uint256 _pricePerToken, IDropWithTiers.AllowlistProof _allowlistProof, string tier) external view
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _claimer | address | undefined |
| _quantity | uint256 | undefined |
| _currency | address | undefined |
| _pricePerToken | uint256 | undefined |
| _allowlistProof | IDropWithTiers.AllowlistProof | undefined |
| tier | string | undefined |



## Events

### ClaimConditionUpdated

```solidity
event ClaimConditionUpdated(IDropWithTiers.ClaimConditionForTier condition, bool resetEligibility)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| condition  | IDropWithTiers.ClaimConditionForTier | undefined |
| resetEligibility  | bool | undefined |

### TokensClaimed

```solidity
event TokensClaimed(address indexed claimer, address indexed receiver, string indexed tier, uint256 startTokenId, uint256 quantityClaimed)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| tier `indexed` | string | undefined |
| startTokenId  | uint256 | undefined |
| quantityClaimed  | uint256 | undefined |



