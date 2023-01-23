# VRFV2WrapperConsumerBase





*******************************************************************************Interface for contracts using VRF randomness through the VRF V2 wrapper ********************************************************************************

*PURPOSECreate VRF V2 requests without the need for subscription management. Rather than creatingand funding a VRF V2 subscription, a user can use this wrapper to create one off requests,paying up front rather than at fulfillment.Since the price is determined using the gas price of the request transaction rather thanthe fulfillment transaction, the wrapper charges an additional premium on callback gasusage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract. *****************************************************************************USAGECalling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be fundedwith enough LINK to make the request, otherwise requests will revert. To request randomness,call the &#39;requestRandomness&#39; function with the desired VRF parameters. This function handlespaying for the request based on the current pricing.Consumers must implement the fullfillRandomWords function, which will be called duringfulfillment with the randomness result.*

## Methods

### rawFulfillRandomWords

```solidity
function rawFulfillRandomWords(uint256 _requestId, uint256[] _randomWords) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _requestId | uint256 | undefined |
| _randomWords | uint256[] | undefined |




