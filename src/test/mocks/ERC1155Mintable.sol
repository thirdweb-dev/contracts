// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

contract ERC1155Mintable is ERC1155PresetMinterPauser {
    constructor() ERC1155PresetMinterPauser("ipfs://BaseURI") {}

    function hasRole(bytes32 _role, address _account) public view override returns (bool) {
        return true;
    }
}
