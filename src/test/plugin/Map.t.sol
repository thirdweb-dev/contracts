// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/extension/plugin/Map.sol";
import { BaseTest } from "../utils/BaseTest.sol";

contract MapTest is BaseTest {
    Map internal map;

    address[] private extensions;
    IMap.ExtensionMap[] private extensionMaps;

    function setUp() public override {
        super.setUp();

        uint256 total = 50;

        address extension;

        for (uint256 i = 0; i < total; i += 1) {
            if (i % 10 == 0) {
                extension = address(uint160(0x50000 + i));
                extensions.push(extension);
            }
            extensionMaps.push(IMap.ExtensionMap(bytes4(keccak256(abi.encode(i))), extension));
        }

        map = new Map(extensionMaps);
    }

    function test_state_getExtensionForFunction() external {
        uint256 len = extensionMaps.length;
        for (uint256 i = 0; i < len; i += 1) {
            address extension = extensionMaps[i].extension;
            bytes4 selector = extensionMaps[i].selector;

            assertEq(extension, map.getExtensionForFunction(selector));
        }
    }

    function test_state_getAllFunctionsOfExtension() external {
        uint256 len = extensions.length;
        for (uint256 i = 0; i < len; i += 1) {
            address extension = extensions[i];

            uint256 expectedNum;

            for (uint256 j = 0; j < extensionMaps.length; j += 1) {
                if (extensionMaps[j].extension == extension) {
                    expectedNum += 1;
                }
            }

            bytes4[] memory expectedFns = new bytes4[](expectedNum);
            uint256 idx;

            for (uint256 j = 0; j < extensionMaps.length; j += 1) {
                if (extensionMaps[j].extension == extension) {
                    expectedFns[idx] = extensionMaps[j].selector;
                    idx += 1;
                }
            }

            bytes4[] memory fns = map.getAllFunctionsOfExtension(extension);

            assertEq(fns.length, expectedNum);

            for (uint256 k = 0; k < fns.length; k += 1) {
                assertEq(fns[k], expectedFns[k]);
            }
        }
    }

    function test_state_getAllRegistered() external {
        IMap.ExtensionMap[] memory extensionMapsStored = map.getAllRegistered();

        for (uint256 i = 0; i < extensionMapsStored.length; i += 1) {
            assertEq(extensionMapsStored[i].extension, extensionMaps[i].extension);
            assertEq(extensionMapsStored[i].selector, extensionMaps[i].selector);
        }
    }
}
