// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Tokens
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "../Pack.sol";

contract Pack_PL is Pack {
    constructor(
        address payable _controlCenter,
        string memory _uri,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fees,
        address _trustedForwarder
    ) Pack(_controlCenter, _uri, _vrfCoordinator, _linkToken, _keyHash, _fees, _trustedForwarder) {
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return role == MINTER_ROLE || super.hasRole(role, account);
    }
}
