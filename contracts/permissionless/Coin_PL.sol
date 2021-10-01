// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Base
import { Coin } from "../Coin.sol";

contract Coin_PL is Coin {
    constructor(
        address payable _controlCenter,
        string memory _name,
        string memory _symbol,
        address _trustedForwarder,
        string memory _uri
    ) Coin(_controlCenter, _name, _symbol, _trustedForwarder, _uri) {}

    /// @dev Ignore MINTER_ROLE
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return role == MINTER_ROLE || super.hasRole(role, account);
    }
}
