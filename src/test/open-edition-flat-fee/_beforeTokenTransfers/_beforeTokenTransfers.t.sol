// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { OpenEditionERC721FlatFee } from "contracts/prebuilts/open-edition/OpenEditionERC721FlatFee.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import "src/test/utils/BaseTest.sol";

contract OpenEditionERC721FlatFeeHarness is OpenEditionERC721FlatFee {
    function beforeTokenTransfers(address from, address to, uint256 startTokenId_, uint256 quantity) public {
        _beforeTokenTransfers(from, to, startTokenId_, quantity);
    }
}

contract OpenEditionERC721FlatFeeTest_beforeTokenTransfers is BaseTest {
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

    function test_revert_transfersRestricted() public {
        address from = address(0x1);
        address to = address(0x2);
        bytes32 role = keccak256("TRANSFER_ROLE");
        vm.prank(deployer);
        openEdition.revokeRole(role, address(0));

        vm.expectRevert(bytes("!T"));
        openEdition.beforeTokenTransfers(from, to, 0, 1);
    }
}
