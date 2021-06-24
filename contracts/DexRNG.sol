// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DexRNG is Ownable {

  uint public currentPairIndex;
  uint internal seed;

  bool public isExternalService;

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

  constructor() {}

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

  /// @dev View function - non state changing random number function.
  function viewRandomNumber(uint range) external view returns (uint randomNumber) {
    require(currentPairIndex > 0, "No Uniswap pairs available to draw randomness from.");
    
    uint blockSignature = uint(keccak256(abi.encodePacked(msg.sender, seed, uint(blockhash(block.number - 1)))));

    for(uint i = 1; i < currentPairIndex; i++) {

      if(!active[pairs[i].pair]) {
        continue;
      }

      PairAddresses memory pairInfo = pairs[i];

      (uint reserveA, uint reserveB,) = getReserves(pairInfo.pair, pairInfo.tokenA, pairInfo.tokenB);
      
      uint randomMod = (reserveA + reserveB) % (range + 73);
      blockSignature += randomMod;
    }

    randomNumber = blockSignature % range;
  }

  /// @dev Returns whether the RNG is using an external service for random number generation.
  function usingExternalService() external view returns (bool) {
    return isExternalService;
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