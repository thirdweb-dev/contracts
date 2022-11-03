# IClaimConditionMultiPhase





The interface `IClaimConditionMultiPhase` is written for thirdweb&#39;s &#39;Drop&#39; contracts, which are distribution mechanisms for tokens.  An authorized wallet can set a series of claim conditions, ordered by their respective `startTimestamp`.  A claim condition defines criteria under which accounts can mint tokens. Claim conditions can be overwritten  or added to by the contract admin. At any moment, there is only one active claim condition.





