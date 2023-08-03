# BurnToClaim









## Methods

### setBurnToClaimInfo

```solidity
function setBurnToClaimInfo(IBurnToClaim.BurnToClaimInfo _burnToClaimInfo) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _burnToClaimInfo | IBurnToClaim.BurnToClaimInfo | undefined |

### verifyBurnToClaim

```solidity
function verifyBurnToClaim(address _tokenOwner, uint256 _tokenId, uint256 _quantity) external view
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _tokenOwner | address | undefined |
| _tokenId | uint256 | undefined |
| _quantity | uint256 | undefined |



## Events

### TokensBurnedAndClaimed

```solidity
event TokensBurnedAndClaimed(address indexed originContract, address indexed tokenOwner, uint256 indexed burnTokenId, uint256 quantity)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| originContract `indexed` | address | undefined |
| tokenOwner `indexed` | address | undefined |
| burnTokenId `indexed` | uint256 | undefined |
| quantity  | uint256 | undefined |



