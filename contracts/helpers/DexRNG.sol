// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract DexRNG {

  /// @dev Number of pairs added.
  uint public currentPairIndex;
  /// @dev Updates on every RNG request.
  uint internal seed;

  /// @dev Uniswap v2 / Sushiswap pairs.
  struct PairAddresses {
    address tokenA;
    address tokenB;
    address pair;

    uint lastUpdateTimeStamp;
  }

  /// @dev Pair index => Pair info.
  mapping(uint => PairAddresses) public pairs;

  /// @dev Pair address => pair index.
  mapping(address => uint) public pairIndex;

  /// @dev Pair address => whether the pair is used by the RNG.
  mapping(address => bool) public active;

  /// @dev Block number => whether at least one pair updated in that block.
  mapping(uint => bool) public blockEntropy;
  
  /// @dev Events.
  event RandomNumber(address indexed requester, uint randomNumber);
  event PairAdded(address pair, address tokenA, address tokenB);
  event PairStatusUpdated(address pair, bool active);

  /**
   *  External functions
  **/

  /// @dev Add a UniswapV2/Sushiswap pair to draw randomness from.
  function addPair(address _pair) public virtual {
    require(IUniswapV2Pair(_pair).MINIMUM_LIQUIDITY() == 1000, "DEX RNG:Invalid pair address provided.");
    require(pairIndex[_pair] == 0, "DEX RNG: This pair already exists as a randomness source.");
    
    // Update pair index.
    currentPairIndex += 1;

    // Store pair.
    pairs[currentPairIndex] = PairAddresses({
      tokenA: IUniswapV2Pair(_pair).token0(),
      tokenB: IUniswapV2Pair(_pair).token1(),
      pair: _pair,
      lastUpdateTimeStamp: 0
    });

    pairIndex[_pair] = currentPairIndex;
    active[_pair] = true;

    emit PairAdded(_pair, pairs[currentPairIndex].tokenA, pairs[currentPairIndex].tokenB);
  }

  /// @dev Sets whether a UniswapV2 pair is actively used as a source of randomness.
  function changePairStatus(address _pair, bool _activeStatus) public virtual {
    require(pairIndex[_pair] != 0, "DEX RNG: Cannot change the status of a pair that does not exist.");

    active[_pair] = _activeStatus;
    
    emit PairStatusUpdated(_pair, _activeStatus);
  }

  /// @dev Returns a random number within the given range.s
  function getRandomNumber(uint range) public virtual returns (uint randomNumber, bool acceptableEntropy) {
    require(currentPairIndex > 0, "DEX RNG: No Uniswap pairs available to draw randomness from.");

    // Check whether pairs have already updated in this block.
    acceptableEntropy = blockEntropy[block.number];
    
    uint blockSignature = uint(keccak256(abi.encodePacked(tx.origin, seed, uint(blockhash(block.number - 1)))));

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
    seed = uint(keccak256(abi.encodePacked(tx.origin, randomNumber)));
    
    emit RandomNumber(tx.origin, randomNumber);
  }

  /**
   *  Internal functions
  **/

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
    require(tokenA != tokenB, "DEX RNG: UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "DEX RNG: UniswapV2Library: ZERO_ADDRESS");
  }
}