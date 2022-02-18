// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/stdlib.sol";
import "@ds-test/test.sol";

abstract contract BaseTest is DSTest, stdCheats {
    Vm public constant vm = Vm(HEVM_ADDRESS);
}
