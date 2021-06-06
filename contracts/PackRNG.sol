// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";

import "./interfaces/RNGInterface.sol";
import "./interfaces/RNGReceiver.sol";

contract PackRNG is RNGInterface, VRFConsumerBase, Ownable {

  RNGReceiver internal randomNumReceiver;

  event KeyHashSet(bytes32 keyHash);
  event FeeSet(uint fee);
  event VrfCoordinatorSet(address indexed vrfCoordinator);
  event VRFRequested(uint indexed requestId, bytes32 indexed chainlinkRequestId);
  event RNGReceiverSet(address randomNumReceiver);

  /// @dev The keyhash used by the Chainlink VRF
  bytes32 public keyHash;

  /// @dev The request fee of the Chainlink VRF
  uint public fee;

  /// @dev A counter for the number of requests made used for request ids
  uint public requestCount;

  /// @dev A list of random numbers from past requests mapped by request id
  mapping(uint => uint) internal randomNumbers;

  /// @dev A list of blocks to be locked at based on past requests mapped by request id
  mapping(uint => uint) internal requestLockBlock;

  /// @dev A mapping from Chainlink request ids to internal request ids
  mapping(bytes32 => uint) internal chainlinkRequestIds;

  /// @dev Public constructor
  constructor(
    address _vrfCoordinator,
    address _link,
    address _randomNumReceiver
  ) VRFConsumerBase(_vrfCoordinator, _link) {
    randomNumReceiver = RNGReceiver(_randomNumReceiver);

    emit RNGReceiverSet(_randomNumReceiver);
    emit VrfCoordinatorSet(_vrfCoordinator);
  }

  function getLink() external view returns (address) {
    return address(LINK);
  }

  /// @notice Allows governance to set the VRF keyhash
  /// @param _keyhash The keyhash to be used by the VRF
  function setKeyhash(bytes32 _keyhash) external onlyOwner {
    keyHash = _keyhash;

    emit KeyHashSet(keyHash);
  }

  /// @notice Allows governance to set the fee per request required by the VRF
  /// @param _fee The fee to be charged for a request
  function setFee(uint _fee) external onlyOwner {
    fee = _fee;

    emit FeeSet(fee);
  }

  /// @notice Gets the last request id used by the RNG service
  /// @return requestId The last request id used in the last request
  function getLastRequestId() external view override returns (uint requestId) {
    return requestCount;
  }

  /// @notice Gets the Fee for making a Request against an RNG service
  /// @return feeToken The address of the token that is used to pay fees
  /// @return requestFee The fee required to be paid to make a request
  function getRequestFee() external override view returns (address feeToken, uint requestFee) {
    return (address(LINK), fee);
  }

  /// @notice Sends a request for a random number to the 3rd-party service
  /// @dev Some services will complete the request immediately, others may have a time-delay
  /// @dev Some services require payment in the form of a token, such as $LINK for Chainlink VRF
  /// @return requestId The ID of the request used to get the results of the RNG service
  /// @return lockBlock The block number at which the RNG service will start generating time-delayed randomness.  The calling contract
  /// should "lock" all activity until the result is available via the `requestId`
  function requestRandomNumber() external override returns (uint requestId, uint lockBlock) {
    uint seed = _getSeed();
    lockBlock = uint(block.number);

    // collect fee for payment
    require(LINK.transferFrom(msg.sender, address(this), fee), "RNGChainlink/fee-transfer-failed");

    // send request (costs fee)
    requestId = _requestRandomness(seed);

    requestLockBlock[requestId] = lockBlock;
 
    emit RandomNumberRequested(requestId, msg.sender);
  }

  /// @notice Checks if the request for randomness from the 3rd-party service has completed
  /// @dev For time-delayed requests, this function is used to check/confirm completion
  /// @param requestId The ID of the request used to get the results of the RNG service
  /// @return isCompleted True if the request has completed and a random number is available, false otherwise
  function isRequestComplete(uint requestId) external override view returns (bool isCompleted) {
    return randomNumbers[requestId] != 0;
  }

  /// @notice Gets the random number produced by the 3rd-party service
  /// @param requestId The ID of the request used to get the results of the RNG service
  /// @return randomNum The random number
  function randomNumber(uint requestId) external view override returns (uint randomNum) {
    return randomNumbers[requestId];
  }

  /// @dev Requests a new random number from the Chainlink VRF
  /// @dev The result of the request is returned in the function `fulfillRandomness`
  /// @param seed The seed used as entropy for the request
  function _requestRandomness(uint seed) internal returns (uint requestId) {
    // Get next request ID
    requestId = _getNextRequestId();

    // Complete request
    bytes32 vrfRequestId = requestRandomness(keyHash, fee, seed);
    chainlinkRequestIds[vrfRequestId] = requestId;

    emit VRFRequested(requestId, vrfRequestId);
  }

  /// @notice Callback function used by VRF Coordinator
  /// @dev The VRF Coordinator will only send this function verified responses.
  /// @dev The VRF Coordinator will not pass randomness that could not be verified.
  function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
    uint internalRequestId = chainlinkRequestIds[requestId];

    // Store random value
    randomNumbers[internalRequestId] = randomness;

    // Call RNGReceiver with random number and internal requestId
    randomNumReceiver.fulfillRandomness(internalRequestId, randomness);

    emit RandomNumberCompleted(internalRequestId, randomness);
  }

  /// @dev Gets the next consecutive request ID to be used
  /// @return requestId The ID to be used for the next request
  function _getNextRequestId() internal returns (uint requestId) {
    requestCount += 1;
    requestId = requestCount;
  }

  /// @dev Gets a seed for a random number from the latest available blockhash
  /// @return seed The seed to be used for generating a random number
  function _getSeed() internal virtual view returns (uint seed) {
    return uint(blockhash(block.number - 1));
  }
}