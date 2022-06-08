# Drop









## Methods

### claim

```solidity
function claim(address _receiver, uint256 _quantity, address _currency, uint256 _pricePerToken, IDrop.AllowlistProof _allowlistProof, bytes _data) external payable
```



*Lets an account claim tokens.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _receiver | address | undefined
| _quantity | uint256 | undefined
| _currency | address | undefined
| _pricePerToken | uint256 | undefined
| _allowlistProof | IDrop.AllowlistProof | undefined
| _data | bytes | undefined

### claimCondition

```solidity
function claimCondition() external view returns (uint256 currentStartId, uint256 count)
```



*The active conditions for claiming tokens.*


#### Returns

| Name | Type | Description |
|---|---|---|
| currentStartId | uint256 | undefined
| count | uint256 | undefined

### getActiveClaimConditionId

```solidity
function getActiveClaimConditionId() external view returns (uint256)
```



*At any given moment, returns the uid for the active claim condition.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined

### getClaimConditionById

```solidity
function getClaimConditionById(uint256 _conditionId) external view returns (struct IClaimCondition.ClaimCondition condition)
```



*Returns the claim condition at the given uid.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _conditionId | uint256 | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| condition | IClaimCondition.ClaimCondition | undefined

### getClaimTimestamp

```solidity
function getClaimTimestamp(uint256 _conditionId, address _claimer) external view returns (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp)
```



*Returns the timestamp for when a claimer is eligible for claiming NFTs again.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _conditionId | uint256 | undefined
| _claimer | address | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| lastClaimTimestamp | uint256 | undefined
| nextValidClaimTimestamp | uint256 | undefined

### setClaimConditions

```solidity
function setClaimConditions(IClaimCondition.ClaimCondition[] _conditions, bool _resetClaimEligibility) external nonpayable
```



*Lets a contract admin set claim conditions.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _conditions | IClaimCondition.ClaimCondition[] | undefined
| _resetClaimEligibility | bool | undefined

### verifyClaim

```solidity
function verifyClaim(uint256 _conditionId, address _claimer, uint256 _quantity, address _currency, uint256 _pricePerToken, bool verifyMaxQuantityPerTransaction) external view
```



*Checks a request to claim NFTs against the active claim condition&#39;s criteria.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _conditionId | uint256 | undefined
| _claimer | address | undefined
| _quantity | uint256 | undefined
| _currency | address | undefined
| _pricePerToken | uint256 | undefined
| verifyMaxQuantityPerTransaction | bool | undefined

### verifyClaimMerkleProof

```solidity
function verifyClaimMerkleProof(uint256 _conditionId, address _claimer, uint256 _quantity, IDrop.AllowlistProof _allowlistProof) external view returns (bool validMerkleProof, uint256 merkleProofIndex)
```



*Checks whether a claimer meets the claim condition&#39;s allowlist criteria.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _conditionId | uint256 | undefined
| _claimer | address | undefined
| _quantity | uint256 | undefined
| _allowlistProof | IDrop.AllowlistProof | undefined

#### Returns

| Name | Type | Description |
|---|---|---|
| validMerkleProof | bool | undefined
| merkleProofIndex | uint256 | undefined



## Events

### ClaimConditionsUpdated

```solidity
event ClaimConditionsUpdated(IClaimCondition.ClaimCondition[] claimConditions)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| claimConditions  | IClaimCondition.ClaimCondition[] | undefined |

### TokensClaimed

```solidity
event TokensClaimed(uint256 indexed claimConditionIndex, address indexed claimer, address indexed receiver, uint256 startTokenId, uint256 quantityClaimed)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| claimConditionIndex `indexed` | uint256 | undefined |
| claimer `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| startTokenId  | uint256 | undefined |
| quantityClaimed  | uint256 | undefined |



