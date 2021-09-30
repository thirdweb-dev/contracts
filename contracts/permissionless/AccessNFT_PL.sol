// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "../AccessNFT.sol";

contract AccessNFT_PL is AccessNFT {
    constructor(
        address payable _controlCenter,
        address _trustedForwarder,
        string memory _uri
    ) AccessNFT(_controlCenter, _trustedForwarder, _uri) {
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return role == MINTER_ROLE || super.hasRole(role, account);
    }
}
