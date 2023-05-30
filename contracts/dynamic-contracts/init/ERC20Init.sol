// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { ERC20Storage } from "../eip/ERC20Upgradeable.sol";
import "../extension/Initializable.sol";

contract ERC20Init is Initializable {
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        ERC20Storage.Data storage data = ERC20Storage.erc20Storage();
        data._name = name_;
        data._symbol = symbol_;
    }
}
