// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface RNGReceiver {

  /// @notice Called by the RNG contract with a random number for a given random number request.
  /// @param requestId The unique ID of the random number request to fulfill.
  /// @param randomness The random number for the given random number request.
  function fulfillRandomness(uint requestId, uint randomness) external;
}