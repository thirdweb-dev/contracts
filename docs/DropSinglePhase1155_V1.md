# DropSinglePhase1155_V1









## Methods

### claim

```solidity
function claim(address _receiver, uint256 _tokenId, uint256 _quantity, address _currency, uint256 _pricePerToken, IDropSinglePhase1155_V1.AllowlistProof _allowlistProof, bytes _data) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _receiver | address | undefined |
| _tokenId | uint256 | undefined |
| _quantity | uint256 | undefined |
| _currency | address | undefined |
| _pricePerToken | uint256 | undefined |
| _allowlistProof | IDropSinglePhase1155_V1.AllowlistProof | undefined |
| _data | bytes | undefined |

### claimCondition

```solidity
function claimCondition(uint256) external view returns (uint256 startTimestamp, uint256 maxClaimableSupply, uint256 supplyClaimed, uint256 quantityLimitPerTransaction, uint256 waitTimeInSecondsBetweenClaims, bytes32 merkleRoot, uint256 pricePerToken, address currency)
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
| quantityLimitPerTransaction | uint256 | undefined |
| waitTimeInSecondsBetweenClaims | uint256 | undefined |
| merkleRoot | bytes32 | undefined |
| pricePerToken | uint256 | undefined |
| currency | address | undefined |

### getClaimTimestamp

```solidity
function getClaimTimestamp(uint256 _tokenId, address _claimer) external view returns (uint256 lastClaimedAt, uint256 nextValidClaimTimestamp)
```



*Returns the timestamp for when a claimer is eligible for claiming NFTs again.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined |
| _claimer | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| lastClaimedAt | uint256 | undefined |
| nextValidClaimTimestamp | uint256 | undefined |

### setClaimConditions

```solidity
function setClaimConditions(uint256 _tokenId, IClaimCondition_V1.ClaimCondition _condition, bool _resetClaimEligibility) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined |
| _condition | IClaimCondition_V1.ClaimCondition | undefined |
| _resetClaimEligibility | bool | undefined |

### verifyClaim

```solidity
function verifyClaim(uint256 _tokenId, address _claimer, uint256 _quantity, address _currency, uint256 _pricePerToken, bool verifyMaxQuantityPerTransaction) external view
```



*Checks a request to claim NFTs against the active claim condition&#39;s criteria.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined |
| _claimer | address | undefined |
| _quantity | uint256 | undefined |
| _currency | address | undefined |
| _pricePerToken | uint256 | undefined |
| verifyMaxQuantityPerTransaction | bool | undefined |

### verifyClaimMerkleProof

```solidity
function verifyClaimMerkleProof(uint256 _tokenId, address _claimer, uint256 _quantity, IDropSinglePhase1155_V1.AllowlistProof _allowlistProof) external view returns (bool validMerkleProof, uint256 merkleProofIndex)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenId | uint256 | undefined |
| _claimer | address | undefined |
| _quantity | uint256 | undefined |
| _allowlistProof | IDropSinglePhase1155_V1.AllowlistProof | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| validMerkleProof | bool | undefined |
| merkleProofIndex | uint256 | undefined |



## Events

### ClaimConditionUpdated

```solidity
event ClaimConditionUpdated(uint256 indexed tokenId, IClaimCondition_V1.ClaimCondition condition, bool resetEligibility)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenId `indexed` | uint256 | undefined |
| condition  | IClaimCondition_V1.ClaimCondition | undefined |
| resetEligibility  | bool | undefined |

### TokensClaimed

```solidity
event TokensClaimed(address indexed claimer, address indexed receiver, uint256 indexed tokenId, uint256 quantityClaimed)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId `indexed` | uint256 | undefined |
| quantityClaimed  | uint256 | undefined |



