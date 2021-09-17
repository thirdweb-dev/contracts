// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

// Token + Access Control
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

// Meta transactions
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import { Forwarder } from "./Forwarder.sol";

contract Coin is ERC20PresetMinterPauser, ERC2771Context {
    constructor(
        string memory _name,
        string memory _symbol,
        address _trustedForwarder
    ) ERC20PresetMinterPauser(_name, _symbol) ERC2771Context(_trustedForwarder) {}

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
