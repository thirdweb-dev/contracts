// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {

    uint256 nextTokenIdToMint;

    constructor() ERC721("MockERC721", "MOCK") {}

    function mint(uint256 _amount) external {
        uint256 tokenId = nextTokenIdToMint;
        nextTokenIdToMint += _amount;

        for(uint256 i = 0; i < _amount; i += 1) {
            _mint(msg.sender, tokenId);
            tokenId += 1;
        }
    }
}