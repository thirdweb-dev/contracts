// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155 } from "contracts/prebuilts/drop/DropERC1155.sol";

// Test imports

import "../../../utils/BaseTest.sol";
import "../../../../../lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC2981Upgradeable.sol";
import "../../../../../lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC1155Upgradeable.sol";
import "../../../../../lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC1155MetadataURIUpgradeable.sol";

contract DropERC1155Test_misc is BaseTest {
    DropERC1155 public drop;

    bytes private emptyEncodedBytes = abi.encode("", "");

    function setUp() public override {
        super.setUp();
        drop = DropERC1155(getContract("DropERC1155"));
    }

    /*///////////////////////////////////////////////////////////////
                        Branch Testing
    //////////////////////////////////////////////////////////////*/

    modifier lazyMint() {
        vm.prank(deployer);
        drop.lazyMint(10, "ipfs://", emptyEncodedBytes);
        _;
    }

    function test_nextTokenIdToMint_ZeroLazyMinted() public {
        uint256 nextTokenIdToMint = drop.nextTokenIdToMint();
        assertEq(nextTokenIdToMint, 0);
    }

    function test_nextTokenIdToMint_TenLazyMinted() public lazyMint {
        uint256 nextTokenIdToMint = drop.nextTokenIdToMint();
        assertEq(nextTokenIdToMint, 10);
    }

    function test_contractType() public {
        assertEq(drop.contractType(), bytes32("DropERC1155"));
    }

    function test_contractVersion() public {
        assertEq(drop.contractVersion(), uint8(4));
    }

    function test_supportsInterface() public {
        assertEq(drop.supportsInterface(type(IERC2981Upgradeable).interfaceId), true);
        assertEq(drop.supportsInterface(type(IERC1155Upgradeable).interfaceId), true);
        assertEq(drop.supportsInterface(type(IERC1155MetadataURIUpgradeable).interfaceId), true);
    }

    function test__msgData() public {
        HarnessDropERC1155MsgData msgDataDrop = new HarnessDropERC1155MsgData();
        bytes memory msgData = msgDataDrop.msgData();
        bytes4 expectedData = msgDataDrop.msgData.selector;
        assertEq(bytes4(msgData), expectedData);
    }
}

contract HarnessDropERC1155MsgData is DropERC1155 {
    function msgData() public view returns (bytes memory) {
        return _msgData();
    }
}
