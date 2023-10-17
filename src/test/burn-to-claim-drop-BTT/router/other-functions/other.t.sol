// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../utils/BaseTest.sol";
import { BurnToClaimDropERC721 } from "contracts/prebuilts/unaudited/burn-to-claim-drop/BurnToClaimDropERC721.sol";

import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract BurnToClaimDropERC721Router is BurnToClaimDropERC721 {
    constructor(Extension[] memory _extensions) BurnToClaimDropERC721(_extensions) {}

    function isAuthorizedCallToUpgrade() public view returns (bool) {
        return _isAuthorizedCallToUpgrade();
    }
}

contract BurnToClaimDropERC721_OtherFunctions is BaseTest, IExtension {
    address public implementation;
    address public proxy;

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        Extension[] memory extensions;
        implementation = address(new BurnToClaimDropERC721Router(extensions));

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = address(
            new TWProxy(
                implementation,
                abi.encodeCall(
                    BurnToClaimDropERC721.initialize,
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
        );
    }

    function test_contractType() public {
        BurnToClaimDropERC721Router router = BurnToClaimDropERC721Router(payable(proxy));
        assertEq(router.contractType(), bytes32("BurnToClaimDropERC721"));
    }

    function test_contractVersion() public {
        BurnToClaimDropERC721Router router = BurnToClaimDropERC721Router(payable(proxy));
        assertEq(router.contractVersion(), uint8(5));
    }

    function test_isAuthorizedCallToUpgrade_notExtensionRole() public {
        BurnToClaimDropERC721Router router = BurnToClaimDropERC721Router(payable(proxy));
        assertFalse(router.isAuthorizedCallToUpgrade());
    }

    modifier whenExtensionRole() {
        _;
    }

    function test_isAuthorizedCallToUpgrade() public whenExtensionRole {
        BurnToClaimDropERC721Router router = BurnToClaimDropERC721Router(payable(proxy));

        vm.prank(deployer);
        assertTrue(router.isAuthorizedCallToUpgrade());
    }
}
