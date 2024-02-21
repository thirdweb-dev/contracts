// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { OpenEditionERC721FlatFee } from "contracts/prebuilts/open-edition/OpenEditionERC721FlatFee.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import "src/test/utils/BaseTest.sol";

contract OpenEditionERC721FlatFeeHarness is OpenEditionERC721FlatFee {
    function canSetPrimarySaleRecipient() external view returns (bool) {
        return _canSetPrimarySaleRecipient();
    }

    function canSetOwner() external view returns (bool) {
        return _canSetOwner();
    }

    /// @dev Checks whether royalty info can be set in the given execution context.
    function canSetRoyaltyInfo() external view returns (bool) {
        return _canSetRoyaltyInfo();
    }

    /// @dev Checks whether contract metadata can be set in the given execution context.
    function canSetContractURI() external view returns (bool) {
        return _canSetContractURI();
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function canSetClaimConditions() external view returns (bool) {
        return _canSetClaimConditions();
    }

    /// @dev Returns whether the shared metadata of tokens can be set in the given execution context.
    function canSetSharedMetadata() external view virtual returns (bool) {
        return _canSetSharedMetadata();
    }
}

contract OpenEditionERC721FlatFeeTest_canSetFunctions is BaseTest {
    OpenEditionERC721FlatFeeHarness public openEdition;

    address private openEditionImpl;

    function setUp() public override {
        super.setUp();
        openEditionImpl = address(new OpenEditionERC721FlatFeeHarness());
        vm.prank(deployer);
        openEdition = OpenEditionERC721FlatFeeHarness(
            address(
                new TWProxy(
                    openEditionImpl,
                    abi.encodeCall(
                        OpenEditionERC721FlatFee.initialize,
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
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: misc
    //////////////////////////////////////////////////////////////*/

    function test_canSetPrimarySaleRecipient_returnTrue() public {
        vm.prank(deployer);
        assertTrue(openEdition.canSetPrimarySaleRecipient());
    }

    function test_canSetPrimarySaleRecipient_returnFalse() public {
        assertFalse(openEdition.canSetPrimarySaleRecipient());
    }

    function test_canSetOwner_returnTrue() public {
        vm.prank(deployer);
        assertTrue(openEdition.canSetOwner());
    }

    function test_canSetOwner_returnFalse() public {
        assertFalse(openEdition.canSetOwner());
    }

    function test_canSetRoyaltyInfo_returnTrue() public {
        vm.prank(deployer);
        assertTrue(openEdition.canSetRoyaltyInfo());
    }

    function test_canSetRoyaltyInfo_returnFalse() public {
        assertFalse(openEdition.canSetRoyaltyInfo());
    }

    function test_canSetContractURI_returnTrue() public {
        vm.prank(deployer);
        assertTrue(openEdition.canSetContractURI());
    }

    function test_canSetContractURI_returnFalse() public {
        assertFalse(openEdition.canSetContractURI());
    }

    function test_canSetClaimConditions_returnTrue() public {
        vm.prank(deployer);
        assertTrue(openEdition.canSetClaimConditions());
    }

    function test_canSetClaimConditions_returnFalse() public {
        assertFalse(openEdition.canSetClaimConditions());
    }

    function test_canSetSharedMetadata_returnTrue() public {
        vm.prank(deployer);
        assertTrue(openEdition.canSetSharedMetadata());
    }

    function test_canSetSharedMetadata_returnFalse() public {
        assertFalse(openEdition.canSetSharedMetadata());
    }
}
