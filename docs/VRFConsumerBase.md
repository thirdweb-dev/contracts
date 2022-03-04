# VRFConsumerBase





****************************************************************************Interface for contracts using VRF randomness *****************************************************************************

*PURPOSEReggie the Random Oracle (not his real job) wants to provide randomnessto Vera the verifier in such a way that Vera can be sure he&#39;s notmaking his output up to suit himself. Reggie provides Vera a public keyto which he knows the secret key. Each time Vera provides a seed toReggie, he gives back a value which is computed completelydeterministically from the seed and the secret key.Reggie provides a proof by which Vera can verify that the output wascorrectly computed once Reggie tells it to her, but without that proof,the output is indistinguishable to her from a uniform random samplefrom the output space.The purpose of this contract is to make it easy for unrelated contractsto talk to Vera the verifier about the work Reggie is doing, to providesimple access to a verifiable source of randomness. *****************************************************************************USAGECalling contracts must inherit from VRFConsumerBase, and caninitialize VRFConsumerBase&#39;s attributes in their constructor asshown:contract VRFConsumer {constructor(&lt;other arguments&gt;, address _vrfCoordinator, address _link)VRFConsumerBase(_vrfCoordinator, _link) public {&lt;initialization with other arguments goes here&gt;}}The oracle will have given you an ID for the VRF keypair they havecommitted to (let&#39;s call it keyHash), and have told you the minimum LINKprice for VRF service. Make sure your contract has sufficient LINK, andcall requestRandomness(keyHash, fee, seed), where seed is the input youwant to generate randomness from.Once the VRFCoordinator has received and validated the oracle&#39;s responseto your request, it will call your contract&#39;s fulfillRandomness method.The randomness argument to fulfillRandomness is the actual random valuegenerated from your seed.The requestId argument is generated from the keyHash and the seed bymakeRequestId(keyHash, seed). If your contract could have concurrentrequests open, you can use the requestId to track which seed isassociated with which randomness. See VRFRequestIDBase.sol for moredetails. (See &quot;SECURITY CONSIDERATIONS&quot; for principles to keep in mind,if your contract could have multiple requests in flight simultaneously.)Colliding `requestId`s are cryptographically impossible as long as seedsdiffer. (Which is critical to making unpredictable randomness! See thenext section.) *****************************************************************************SECURITY CONSIDERATIONSA method with the ability to call your fulfillRandomness method directlycould spoof a VRF response with any random value, so it&#39;s critical thatit cannot be directly called by anything other than this base contract(specifically, by the VRFConsumerBase.rawFulfillRandomness method).For your users to trust that your contract&#39;s random behavior is freefrom malicious interference, it&#39;s best if you can write it so that allbehaviors implied by a VRF response are executed *during* yourfulfillRandomness method. If your contract must store the response (oranything derived from it) and use it later, you must ensure that anyuser-significant behavior which depends on that stored value cannot bemanipulated by a subsequent VRF request.Similarly, both miners and the VRF oracle itself have some influenceover the order in which VRF responses appear on the blockchain, so ifyour contract could have multiple VRF requests in flight simultaneously,you must ensure that the order in which the VRF responses arrive cannotbe used to manipulate your contract&#39;s user-significant behavior.Since the ultimate input to the VRF is mixed with the block hash of theblock in which the request is made, user-provided seeds have no impacton its economic security properties. They are only included for APIcompatability with previous versions of this contract.Since the block hash of the block which contains the requestRandomnesscall is mixed into the input to the VRF *last*, a sufficiently powerfulminer could, in principle, fork the blockchain to evict the blockcontaining the request, forcing the request to be included in adifferent block with a different hash, and therefore a different inputto the VRF. However, such an attack would incur a substantial economiccost. This cost scales with the number of blocks the VRF oracle waitsuntil it calls responds to a request.*

## Methods

### rawFulfillRandomness

```solidity
function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| requestId | bytes32 | undefined
| randomness | uint256 | undefined




