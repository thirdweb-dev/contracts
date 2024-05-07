// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC1155 is TokenERC1155 {}

contract TokenERC1155Test_SetContractURI is BaseTest {
    address public implementation;
    address public proxy;
    address internal caller;
    string internal _contractURI;

    MyTokenERC1155 internal tokenContract;

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC1155());

        caller = getActor(1);

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = address(
            new TWProxy(
                implementation,
                abi.encodeCall(
                    TokenERC1155.initialize,
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

        tokenContract = MyTokenERC1155(proxy);
        _contractURI = "ipfs://contracturi";
    }

    function test_setContractURI_callerNotAuthorized() public {
        vm.prank(address(caller));
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(caller), 20),
                " is missing role ",
                Strings.toHexString(uint256(0), 32)
            )
        );
        tokenContract.setContractURI(_contractURI);
    }

    modifier whenCallerAuthorized() {
        vm.prank(deployer);
        tokenContract.grantRole(bytes32(0x00), caller);
        _;
    }

    function test_setContractURI_empty() public whenCallerAuthorized {
        vm.prank(address(caller));
        tokenContract.setContractURI("");

        // get contract uri
        assertEq(tokenContract.contractURI(), "");
    }

    function test_setContractURI_notEmpty() public whenCallerAuthorized {
        vm.prank(address(caller));
        tokenContract.setContractURI(_contractURI);

        // get contract uri
        assertEq(tokenContract.contractURI(), _contractURI);
    }
}
