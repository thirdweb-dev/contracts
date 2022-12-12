// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/base/ERC1155Base.sol";

contract SerumClone is ERC1155Base {
    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC1155Base(_name, _symbol, _royaltyRecipient, _royaltyBps) {}
}
