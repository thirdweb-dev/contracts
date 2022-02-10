// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

contract ERC721Mintable is ERC721PresetMinterPauserAutoId {
    constructor() ERC721PresetMinterPauserAutoId("Mock", "MOCK", "ipfs://BaseURI") {}

    function hasRole(bytes32 _role, address _account) public view override returns (bool) {
        return true;
    }
}
