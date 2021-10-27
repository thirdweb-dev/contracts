// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract DataStore is Context, Multicall, AccessControlEnumerable {
  bytes32 public constant PUBLISHER_ROLE = keccak256("PUBLISHER_ROLE");

  mapping(bytes32 => string) public data;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(PUBLISHER_ROLE, _msgSender());
  }

  function store(bytes32 _key, string memory _value) onlyRole(PUBLISHER_ROLE) external {
    data[_key] = _value;
  }
}

