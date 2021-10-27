// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract DataStore is Context, Multicall, AccessControlEnumerable {
  bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");

  mapping(uint256 => uint256) public data;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(EDITOR_ROLE, _msgSender());
  }

  function store(uint256 _key, uint256 _value) onlyRole(EDITOR_ROLE) external {
    data[_key] = _value;
  }
}

