// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

interface IProtocolControl {
  /// @dev Returns whether the pack protocol is paused.
  function systemPaused() external view returns (bool);
  
  /// @dev Returns the address of the pack protocol treasury.
  function treasury() external view returns(address treasuryAddress);

  /// @dev Returns the address of pack protocol's module.
  function getModule(string memory _moduleName) external view returns (address);

  /// @dev Returns true if account has been granted role.
  function hasRole(bytes32 role, address account) external returns (bool);

  /// @dev Returns true if account has been granted role.
  function PROTOCOL_ADMIN() external view returns (bytes32);
}

interface IListingAsset {
  function creator(uint _tokenId) external view returns (address creator);
}

interface IRNG {
  /// @dev Returns whether the RNG is using an external service for randomness.
  function usingExternalService(uint _packId) external view returns (bool);

  /**
   * @dev Sends a request for random number to an external.
   *      Returns the unique request Id of the request, and the block number of the request.
  **/ 
  function requestRandomNumber() external returns (uint requestId, uint lockBlock);

  /// @notice Gets the Fee for making a Request against an RNG service
  function getRequestFee() external view returns (address feeToken, uint requestFee);

  /// @notice Returns a random number and whether the random number was generated with enough entropy.
  function getRandomNumber(uint range) external returns (uint randomNumber, bool acceptableEntropy);
}

/// @dev Interface for pack protocol's `Pack.sol` as a random number receiver.
interface IRNGReceiver {
  function fulfillRandomness(uint requestId, uint randomness) external;
  
  function creator(uint _packId) external view returns (address creator);
  
  function totalSupply(uint _packId) external view returns (uint totalSupplyOfToken);
}