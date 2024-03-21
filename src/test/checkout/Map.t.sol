// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../utils/BaseTest.sol";

interface IRandom {
    function random() external view returns (uint256);
}

contract MapCheck {
    struct S {
        address addr;
    }
    uint256 public a;
    mapping(bytes4 => S) public myMap;

    constructor() {
        a = 10;
        myMap[IRandom.random.selector] = S({ addr: address(123) });
    }

    function checkA() public view returns (uint256 res) {
        assembly {
            res := sload(0)
        }
    }

    function checkMap() public view returns (uint256 res) {
        bytes4 sel = IRandom.random.selector;
        assembly {
            mstore(0, sel)

            mstore(32, myMap.slot)

            let hash := keccak256(0, 64)
            res := myMap.slot
        }
    }
}

contract MapCheckTest {
    MapCheck internal c;

    function setUp() public {
        c = new MapCheck();
    }

    function test_mappingSlot() public {
        console.log(c.myMap(IRandom.random.selector));
        console.logBytes4(IRandom.random.selector);

        console.log(c.checkA());
        console.log(c.checkMap());
    }
}
