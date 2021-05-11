// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PackCoin is ERC20 {
  constructor() ERC20("Pack Coin", "PKC") {
    require(block.chainid == 3 || block.chainid == 31337, "only ropsten is supported");
  }

  function mint(address to, uint256 amount) public {
    _mint(to, amount);
  }
}
