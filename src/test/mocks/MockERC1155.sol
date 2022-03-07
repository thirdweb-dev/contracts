// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

contract MockERC1155 is ERC1155PresetMinterPauser {
    constructor() ERC1155PresetMinterPauser("ipfs://BaseURI") {}

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public virtual {
        _mint(to, id, amount, "");
    }

    function hasRole(bytes32, address) public pure override(AccessControl, IAccessControl) returns (bool) {
        return true;
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        _mintBatch(to, ids, amounts, "");
    }
}
