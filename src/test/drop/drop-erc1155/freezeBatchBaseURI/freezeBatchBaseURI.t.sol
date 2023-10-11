// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155 } from "contracts/prebuilts/drop/DropERC1155.sol";

// Test imports
import "contracts/lib/TWStrings.sol";
import "../../../utils/BaseTest.sol";
import "../../../../../lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC2981Upgradeable.sol";

contract DropERC1155Test_freezeBatchBaseURI is BaseTest {
    event MetadataFrozen();

    DropERC1155 public drop;

    address private unauthorized = address(0x123);

    bytes private emptyEncodedBytes = abi.encode("", "");

    function setUp() public override {
        super.setUp();
        drop = DropERC1155(getContract("DropERC1155"));
    }

    /*///////////////////////////////////////////////////////////////
                        Branch Testing
    //////////////////////////////////////////////////////////////*/

    modifier callerWithoutMetadataRole() {
        vm.startPrank(unauthorized);
        _;
    }

    modifier callerWithMetadataRole() {
        vm.startPrank(deployer);
        _;
    }

    modifier lazyMint() {
        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        _;
    }

    modifier lazyMintEmptyUri() {
        vm.prank(deployer);
        drop.lazyMint(100, "", emptyEncodedBytes);
        _;
    }

    function test_revert_NoMetadataRole() public lazyMint callerWithoutMetadataRole {
        bytes32 role = keccak256("METADATA_ROLE");
        vm.expectRevert(
            abi.encodePacked(
                "Permissions: account ",
                TWStrings.toHexString(uint160(unauthorized), 20),
                " is missing role ",
                TWStrings.toHexString(uint256(role), 32)
            )
        );
        drop.freezeBatchBaseURI(0);
    }

    function test_revert_IndexTooHigh() public lazyMint callerWithMetadataRole {
        vm.expectRevert("Invalid index");
        drop.freezeBatchBaseURI(1);
    }

    function test_revert_EmptyBaseURI() public lazyMintEmptyUri callerWithMetadataRole {
        vm.expectRevert("Invalid batch");
        drop.freezeBatchBaseURI(0);
    }

    function test_state() public lazyMint callerWithMetadataRole {
        uint256 batchId = drop.getBatchIdAtIndex(0);
        drop.freezeBatchBaseURI(0);
        assertEq(drop.batchFrozen(batchId), true);
    }

    function test_event() public lazyMint callerWithMetadataRole {
        vm.expectEmit(false, false, false, false);
        emit MetadataFrozen();
        drop.freezeBatchBaseURI(0);
    }
}
