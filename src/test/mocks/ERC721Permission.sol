// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

contract ERC721Permission is ERC721PresetMinterPauserAutoId {
    constructor() ERC721PresetMinterPauserAutoId("Mock", "MOCK", "ipfs://BaseURI") {}
}
