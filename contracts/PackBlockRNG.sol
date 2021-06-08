// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/RNGInterface.sol";
import "./interfaces/RNGReceiver.sol";

contract PackBlockRNG is RNGInterface, Ownable {

  RNGReceiver internal randomNumReceiver;
  
  event RNGReceiverSet(address randomNumReceiver);

  /// @dev A counter for the number of requests made used for request ids
  uint public requestCount;

  /// @dev A list of random numbers from past requests mapped by request id
  mapping(uint => uint) internal randomNumbers;

  /// @dev Public constructor
  constructor(address _randomNumReceiver) {
    randomNumReceiver = RNGReceiver(_randomNumReceiver);
    emit RNGReceiverSet(_randomNumReceiver);
  }

  /// @notice Allows governance to set the random number receiver.
  /// @param _randomNumReceiver The address of the new random number receiver.
  function setRNGReceiver(address _randomNumReceiver) external onlyOwner {
    randomNumReceiver = RNGReceiver(_randomNumReceiver);
    emit RNGReceiverSet(_randomNumReceiver);
  }

  /// @notice Gets the last request id used by the RNG service
  /// @return requestId The last request id used in the last request
  function getLastRequestId() external view override returns (uint requestId) {
    return requestCount;
  }

  /// @notice Gets the Fee for making a Request against an RNG service
  /// @return feeToken The address of the token that is used to pay fees
  /// @return requestFee The fee required to be paid to make a request
  function getRequestFee() external override pure returns (address feeToken, uint requestFee) {
    return (address(0), 0);
  }

  /// @notice Sends a request for a random number to the 3rd-party service
  /// @dev Some services will complete the request immediately, others may have a time-delay
  /// @dev Some services require payment in the form of a token, such as $LINK for Chainlink VRF
  /// @return requestId The ID of the request used to get the results of the RNG service
  /// @return lockBlock The block number at which the RNG service will start generating time-delayed randomness. 
  /// The calling contract should "lock" all activity until the result is available via the `requestId`
  function requestRandomNumber() external override returns (uint requestId, uint lockBlock) {
    uint seed = _getSeed();
    lockBlock = uint(block.number);

    // send request (costs fee)
    requestId = _getNextRequestId();
    emit RandomNumberRequested(requestId, msg.sender);

    uint randomness = uint(keccak256(abi.encodePacked(msg.sender, seed, lockBlock)));
    // Store random value
    randomNumbers[requestId] = randomness;

    // Call RNGReceiver with random number and internal requestId
    randomNumReceiver.fulfillRandomness(requestId, randomness);

    emit RandomNumberCompleted(requestId, randomness);
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