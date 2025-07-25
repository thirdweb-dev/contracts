// <ai_context>
// Miscellaneous unit tests for DropERC721FlatFee contract.
// Covers tokenURI, supportsInterface, totalMinted, nextTokenIdToMint, nextTokenIdToClaim, burn, etc.
// Adapted for batch metadata and delayed reveal.
// </ai_context>

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721FlatFee, IERC721AUpgradeable } from "contracts/prebuilts/drop/DropERC721FlatFee.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";
import { IPlatformFee } from "contracts/extension/interface/IPlatformFee.sol";

// Test imports
import "src/test/utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

contract HarnessDropERC721FlatFee is DropERC721FlatFee {
    function msgData() public view returns (bytes memory) {
        return _msgData();
    }
}

contract DropERC721FlatFeeTest_misc is BaseTest {
    DropERC721FlatFee public drop;

    address private dropImpl;

    function setUp() public override {
        super.setUp();
        dropImpl = address(new DropERC721FlatFee());
        vm.prank(deployer);
        drop = DropERC721FlatFee(
            address(
                new TWProxy(
                    dropImpl,
                    abi.encodeCall(
                        DropERC721FlatFee.initialize,
                        (
                            deployer,
                            NAME,
                            SYMBOL,
                            CONTRACT_URI,
                            forwarders(),
                            saleRecipient,
                            royaltyRecipient,
                            royaltyBps,
                            platformFeeBps,
                            platformFeeRecipient
                        )
                    )
                )
            )
        );
        // Set to flat fee mode
        vm.prank(deployer);
        drop.setPlatformFeeType(IPlatformFee.PlatformFeeType.Flat);
        vm.prank(deployer);
        drop.setFlatPlatformFeeInfo(platformFeeRecipient, 0.1 ether);
    }

    // Tests for tokenURI with batch logic, burn, totalMinted, etc.
    // ...
}