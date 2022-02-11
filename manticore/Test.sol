// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

contract Test {
    mapping(address => bool) public canTake;

    constructor() {}

    function set(
        uint256 x,
        uint256 y,
        uint256 z
    ) public payable {
        require(msg.value == 1 ether, "!value");
        require(x == 34, "!x");
        require(y == x + 52, "!y");
        require(z == 132 - y, "!z");
        canTake[msg.sender] = true;
    }

    function take() public {
        require(canTake[msg.sender], "!canTake");
        canTake[msg.sender] = false;
        (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
        require(success, "!success");
    }
}
