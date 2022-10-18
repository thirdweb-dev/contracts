# DropSinglePhase









## Methods

### claim

```solidity
function claim(address _receiver, uint256 _quantity, address _currency, uint256 _pricePerToken, IDropSinglePhase.AllowlistProof _allowlistProof, bytes _data) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _receiver | address | undefined |
| _quantity | uint256 | undefined |
| _currency | address | undefined |
| _pricePerToken | uint256 | undefined |
| _allowlistProof | IDropSinglePhase.AllowlistProof | undefined |
| _data | bytes | undefined |

### claimCondition

```solidity
function claimCondition() external view returns (uint256 startTimestamp, uint256 maxClaimableSupply, uint256 supplyClaimed, uint256 quantityLimitPerWallet, bytes32 merkleRoot, uint256 pricePerToken, address currency, string uri)
```



*The active conditions for claiming tokens.*


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
| uri | string | undefined |

### getSupplyClaimedByWallet

```solidity
function getSupplyClaimedByWallet(address _claimer) external view returns (uint256)
```



*Returns the supply claimed by claimer for active conditionId.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _claimer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### setClaimConditions

```solidity
function setClaimConditions(IClaimCondition.ClaimCondition _condition, bool _resetClaimEligibility) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _condition | IClaimCondition.ClaimCondition | undefined |
| _resetClaimEligibility | bool | undefined |

### verifyClaim

```solidity
function verifyClaim(address _claimer, uint256 _quantity, address _currency, uint256 _pricePerToken, IDropSinglePhase.AllowlistProof _allowlistProof) external view
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _claimer | address | undefined |
| _quantity | uint256 | undefined |
| _currency | address | undefined |
| _pricePerToken | uint256 | undefined |
| _allowlistProof | IDropSinglePhase.AllowlistProof | undefined |



## Events

### ClaimConditionUpdated

```solidity
event ClaimConditionUpdated(IClaimCondition.ClaimCondition condition, bool resetEligibility)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| condition  | IClaimCondition.ClaimCondition | undefined |
| resetEligibility  | bool | undefined |

### TokensClaimed

```solidity
event TokensClaimed(address indexed claimer, address indexed receiver, uint256 indexed startTokenId, uint256 quantityClaimed)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| startTokenId `indexed` | uint256 | undefined |
| quantityClaimed  | uint256 | undefined |



