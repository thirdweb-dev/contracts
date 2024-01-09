// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockERC1155NonBurnable is ERC1155 {
    constructor() ERC1155("ipfs://BaseURI") {}

    function mint(address to, uint256 id, uint256 amount) public virtual {
        _mint(to, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) public virtual {
        _mintBatch(to, ids, amounts, "");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
