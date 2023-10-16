// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { DelayedReveal, IDelayedReveal } from "contracts/extension/DelayedReveal.sol";
import "../../ExtensionUtilTest.sol";

contract MyDelayedReveal is DelayedReveal {
    function setEncryptedData(uint256 _batchId, bytes memory _encryptedData) external {
        _setEncryptedData(_batchId, _encryptedData);
    }

    function reveal(uint256 identifier, bytes calldata key) external returns (string memory revealedURI) {}
}

contract DelayedReveal_SetEncryptedData is ExtensionUtilTest {
    MyDelayedReveal internal ext;
    uint256 internal batchId;
    bytes internal data;

    function setUp() public override {
        super.setUp();

        ext = new MyDelayedReveal();
        batchId = 1;
        data = "test";
    }

    function test_setEncryptedData() public {
        ext.setEncryptedData(batchId, data);

        assertEq(true, ext.isEncryptedBatch(batchId));
        assertEq(ext.encryptedData(batchId), data);
    }
}
