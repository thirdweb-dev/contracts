// <ai_context>
// Unit tests for the internal _canSet* functions in DropERC721FlatFee contract.
// Tests role-based access for setting various contract parameters.
// Includes _canLazyMint specific to drop.
// </ai_context>

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721FlatFee } from "contracts/prebuilts/drop/DropERC721FlatFee.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";
import { IPlatformFee } from "contracts/extension/interface/IPlatformFee.sol";

// Test imports
import "src/test/utils/BaseTest.sol";

contract DropERC721FlatFeeHarness is DropERC721FlatFee {
    function canSetPrimarySaleRecipient() external view returns (bool) {
        return _canSetPrimarySaleRecipient();
    }

    function canSetOwner() external view returns (bool) {
        return _canSetOwner();
    }

    function canSetRoyaltyInfo() external view returns (bool) {
        return _canSetRoyaltyInfo();
    }

    function canSetContractURI() external view returns (bool) {
        return _canSetContractURI();
    }

    function canSetClaimConditions() external view returns (bool) {
        return _canSetClaimConditions();
    }

    function canLazyMint() external view returns (bool) {
        return _canLazyMint();
    }

    function canSetPlatformFeeInfo() external view returns (bool) {
        return _canSetPlatformFeeInfo();
    }
}

contract DropERC721FlatFeeTest_canSetFunctions is BaseTest {
    DropERC721FlatFeeHarness public drop;

    address private dropImpl;

    function setUp() public override {
        super.setUp();
        dropImpl = address(new DropERC721FlatFeeHarness());
        vm.prank(deployer);
        drop = DropERC721FlatFeeHarness(
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

    /*///////////////////////////////////////////////////////////////
                        Unit tests: misc
    //////////////////////////////////////////////////////////////*/

    function test_canSetPrimarySaleRecipient_returnTrue() public {
        vm.prank(deployer);
        assertTrue(drop.canSetPrimarySaleRecipient());
    }

    function test_canSetPrimarySaleRecipient_returnFalse() public {
        assertFalse(drop.canSetPrimarySaleRecipient());
    }

    function test_canSetOwner_returnTrue() public {
        vm.prank(deployer);
        assertTrue(drop.canSetOwner());
    }

    function test_canSetOwner_returnFalse() public {
        assertFalse(drop.canSetOwner());
    }

    function test_canSetRoyaltyInfo_returnTrue() public {
        vm.prank(deployer);
        assertTrue(drop.canSetRoyaltyInfo());
    }

    function test_canSetRoyaltyInfo_returnFalse() public {
        assertFalse(drop.canSetRoyaltyInfo());
    }

    function test_canSetContractURI_returnTrue() public {
        vm.prank(deployer);
        assertTrue(drop.canSetContractURI());
    }

    function test_canSetContractURI_returnFalse() public {
        assertFalse(drop.canSetContractURI());
    }

    function test_canSetClaimConditions_returnTrue() public {
        vm.prank(deployer);
        assertTrue(drop.canSetClaimConditions());
    }

    function test_canSetClaimConditions_returnFalse() public {
        assertFalse(drop.canSetClaimConditions());
    }

    function test_canLazyMint_returnTrue() public {
        vm.prank(deployer);
        assertTrue(drop.canLazyMint());
    }

    function test_canLazyMint_returnFalse() public {
        assertFalse(drop.canLazyMint());
    }

    function test_canSetPlatformFeeInfo_returnTrue() public {
        vm.prank(deployer);
        assertTrue(drop.canSetPlatformFeeInfo());
    }

    function test_canSetPlatformFeeInfo_returnFalse() public {
        assertFalse(drop.canSetPlatformFeeInfo());
    }
}