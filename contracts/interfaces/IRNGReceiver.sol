// SPDX-License-Identifier: GPL-3.0 

pragma solidity >=0.8.0;

interface IRNGReceiver {
  function fulfillRandomness(uint requestId, uint randomness) external;
}