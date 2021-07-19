// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";

import "./helpers/DexRNG.sol";

import { IProtocolControl, IRNGReceiver } from "./Interfaces.sol";

contract RNG is DexRNG, VRFConsumerBase {

  /// @dev The pack protocol admin contract.
  IProtocolControl internal controlCenter;

  /// @dev Pack protocol module names.
  string public constant PACK = "PACK";
  
  /// @dev Wether the RNG uses and external service like Chainlink.
  bool public isExternalService;

  /// @dev Chainlink VRF requirements.
  uint internal fees;
  bytes32 internal keyHash;

  /// @dev Increments by one. Acts as a human readable request ID for each external RNG request.
  uint public currentRequestId;

  /// @dev bytes request ID => human readable integer request ID.
  mapping(bytes32 => uint) public requestIds;

  /// @dev Events.
  event ExternalServiceRequest(address indexed requestor, uint requestId);
  event RandomNumberExternal(uint randomNumber);

  constructor(
    address _controlCenter,

    address _vrfCoordinator,
    address _linkToken,
    bytes32 _keyHash,
    uint _fees

  ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
    controlCenter = IProtocolControl(_controlCenter);

    keyHash = _keyHash;
    fees = _fees;
  }

  /**
   *  Chainlink VRF functions
  **/
  
  /// @dev Sends a random number request to the Chainlink VRF system.
  function requestRandomNumber() external returns (uint requestId) {
    require(msg.sender == address(pack()), "RNG: Only the pack token contract can call this function.");
    
    // Send random number request.
    bytes32 bytesId = requestRandomness(keyHash, fees, block.number);
    
    // Return an integer Id instead of a bytes Id for convenience.
    requestId = currentRequestId;
    requestIds[bytesId] = requestId;

    currentRequestId++;

    emit ExternalServiceRequest(msg.sender, requestId);
  }

  /// @dev Called by Chainlink VRF random number provider.
  function fulfillRandomness(bytes32 requestId, uint randomness) internal override {

    // Call the pack token contract with the retrieved random number.
    pack().fulfillRandomness(requestIds[requestId], randomness);

    emit RandomNumberExternal(randomness);
  }

  /// @dev Returns the fee amount and token to pay fees in.
  function getRequestFee() external view returns(address feeToken, uint feeAmount) {
    return (address(LINK), fees);
  }

  /// @dev Changes the `fees` required by Chainlink VRF.
  function setFees(uint _fees) external {
    require(
      controlCenter.hasRole(controlCenter.PROTOCOL_ADMIN(), msg.sender), 
      "RNG: Only a pack protocol admin can call this function."
    );
    fees = _fees;
  }

  /**
   *  View functions
  **/

  /// @dev Returns whether the RNG is using an external service for random number generation.
  function usingExternalService() external view returns (bool) {
    return isExternalService;
  }

  /// @dev Returns pack protocol's `Pack`
  function pack() internal view returns (IRNGReceiver) {
    return IRNGReceiver(controlCenter.getModule(PACK));
  }
}