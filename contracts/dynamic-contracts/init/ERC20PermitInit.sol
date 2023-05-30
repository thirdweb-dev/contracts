// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { ERC20PermitStorage } from "../eip/draft-ERC20PermitUpgradeable.sol";
import { EIP712Init } from "./EIP712Init.sol";
import "../extension/Initializable.sol";

contract ERC20PermitInit is Initializable, EIP712Init {
    function __ERC20Permit_init(string memory name) internal onlyInitializing {
        __EIP712_init_unchained(name, "1");
    }

    function __ERC20Permit_init_unchained(string memory) internal onlyInitializing {}
}
