// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

contract NFT is ERC721PresetMinterPauserAutoId {
    constructor() ERC721PresetMinterPauserAutoId("ExampleNFT", "EXNFT", "ipfs://dummyuri") {}
}
