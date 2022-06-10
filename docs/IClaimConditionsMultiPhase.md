# IClaimConditionsMultiPhase





Thirdweb&#39;s &#39;Drop&#39; contracts are distribution mechanisms for tokens.  A contract admin (i.e. a holder of `DEFAULT_ADMIN_ROLE`) can set a series of claim conditions,  ordered by their respective `startTimestamp`. A claim condition defines criteria under which  accounts can mint tokens. Claim conditions can be overwritten or added to by the contract admin.  At any moment, there is only one active claim condition.



## Methods

### setClaimConditions

```solidity
function setClaimConditions(IClaimCondition.ClaimCondition[] phases, bool resetClaimEligibility) external nonpayable
```

Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.



#### Parameters

| Name | Type | Description |
|---|---|---|
| phases | IClaimCondition.ClaimCondition[] | Claim conditions in ascending order by `startTimestamp`.
| resetClaimEligibility | bool | Whether to reset `limitLastClaimTimestamp` and `limitMerkleProofClaim` values when setting new                                  claim conditions.



## Events

### ClaimConditionsUpdated

```solidity
event ClaimConditionsUpdated(IClaimCondition.ClaimCondition[] claimConditions)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| claimConditions  | IClaimCondition.ClaimCondition[] | undefined |



