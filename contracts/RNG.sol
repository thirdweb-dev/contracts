// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "./ProtocolControl.sol";

/// @dev Basic interface for a random number receiver.
interface IRNGReceiver {
  function fulfillRandomness(uint requestId, uint randomness) external;
}

contract RNG is Ownable, VRFConsumerBase {

  ProtocolControl internal controlCenter;
  string public constant PACK = "PACK";
  
  /// @dev Chainlink / external RNG service variables.
  bool public isExternalService;
  bytes32 internal keyHash;
  uint public currentRequestId;

  mapping(bytes32 => uint) public requestIds;

  event ExternalServiceRequest(address indexed requestor, uint requestId);
  event RandomNumberExternal(uint randomNumber);

  /// @dev DEX RNG variables.
  uint public currentPairIndex;
  uint internal seed;

  struct PairAddresses {
    address tokenA;
    address tokenB;
    address pair;

    uint lastUpdateTimeStamp;
  }

  mapping(uint => PairAddresses) public pairs;
  mapping(address => uint) public pairIndex;
  mapping(address => bool) public active;
  mapping(uint => bool) public blockEntropy;
  
  event RandomNumber(address indexed requester, uint randomNumber);
  event PairAdded(address pair, address tokenA, address tokenB);
  event PairStatusUpdated(address pair, bool active);

  constructor(
    address _controlCenter,
    address _vrfCoordinator,
    address _linkToken,
    bytes32 _keyHash
  ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
    controlCenter = ProtocolControl(_controlCenter);
    keyHash = _keyHash;
  }

  // ===== Chainlink VRF functions =====
  
  /// @dev Sends a random number request to the Chainlink VRF system.
  function requestRandomNumber() external returns (uint requestId) {
    require(msg.sender == address(pack()), "Only handler can call this function.");
    requestRandomness(keyHash, 0.1 ether, block.number);
    
    requestId = currentRequestId;
    currentRequestId++;

    emit ExternalServiceRequest(msg.sender, requestId);
  }

  /// @dev Called by Chainlink VRF random number provider.
  function fulfillRandomness(bytes32 requestId, uint randomness) internal override {

    // Call handler with the retrieved random number.
    pack().fulfillRandomness(requestIds[requestId], randomness);

    emit RandomNumberExternal(randomness);
  }

  // ===== DEX RNG functions =====

  /// @dev Add a UniswapV2 pair to draw randomness from.
  function addPair(address pair) external onlyOwner {
    require(IUniswapV2Pair(pair).MINIMUM_LIQUIDITY() == 1000, "Invalid pair address provided.");
    require(pairIndex[pair] == 0, "This pair already exists as a randomness source.");
    
    currentPairIndex += 1;

    pairs[currentPairIndex] = PairAddresses({
      tokenA: IUniswapV2Pair(pair).token0(),
      tokenB: IUniswapV2Pair(pair).token1(),
      pair: pair,
      lastUpdateTimeStamp: 0
    });

    pairIndex[pair] = currentPairIndex;
    active[pair] = true;

    emit PairAdded(pair, pairs[currentPairIndex].tokenA, pairs[currentPairIndex].tokenB);
  }

  /// @dev Sets whether a UniswapV2 pair is actively used as a source of randomness.
  function changePairStatus(address pair, bool activeStatus) external onlyOwner {
    require(pairIndex[pair] != 0, "Cannot change the status of a pair that does not exist.");

    active[pair] = activeStatus;
    
    emit PairStatusUpdated(pair, activeStatus);
  }

  /// @dev Returns a random number within the given range;
  function getRandomNumber(uint range) external returns (uint randomNumber, bool acceptableEntropy) {
    require(currentPairIndex > 0, "No Uniswap pairs available to draw randomness from.");

    acceptableEntropy = blockEntropy[block.number];
    
    uint blockSignature = uint(keccak256(abi.encodePacked(msg.sender, seed, uint(blockhash(block.number - 1)))));

    for(uint i = 1; i <= currentPairIndex; i++) {

      if(!active[pairs[i].pair]) {
        continue;
      }

      (uint reserveA, uint reserveB, uint lastUpdateTimeStamp) = getReserves(pairs[i].pair, pairs[i].tokenA, pairs[i].tokenB);
      
      uint randomMod = seed == 0 ? (reserveA + reserveB) % range : (reserveA + reserveB) % (seed % range);
      blockSignature += randomMod;

      if(lastUpdateTimeStamp > pairs[i].lastUpdateTimeStamp) {

        if(!acceptableEntropy) {
          acceptableEntropy = true;
          blockEntropy[block.number] = true;
        }

        pairs[i].lastUpdateTimeStamp = lastUpdateTimeStamp;
      }
    }

    randomNumber = blockSignature % range;
    seed = uint(keccak256(abi.encodePacked(msg.sender, randomNumber)));
    
    emit RandomNumber(msg.sender, randomNumber);
  }

  /// @dev Returns whether the RNG is using an external service for random number generation.
  function usingExternalService() external view returns (bool) {
    return isExternalService;
  }

  /// @dev Returns pack protocol's `Pack`
  function pack() internal view returns (IRNGReceiver) {
    return IRNGReceiver(controlCenter.getModule(PACK));
  }
  
  /// @notice See `UniswapV2Library.sol`
  function getReserves(
    address pair, 
    address tokenA, 
    address tokenB
  ) internal view returns (uint reserveA, uint reserveB, uint lastUpdateTimeStamp) {
    (address token0,) = sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1, uint blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
    (reserveA, reserveB, lastUpdateTimeStamp) = tokenA == token0 ? (reserve0, reserve1, blockTimestampLast) : (reserve1, reserve0, blockTimestampLast);
  }

  /// @notice See `UniswapV2Library.sol`
  function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }
}