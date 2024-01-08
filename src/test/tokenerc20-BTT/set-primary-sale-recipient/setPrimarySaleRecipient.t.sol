// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC20 is TokenERC20 {}

contract TokenERC20Test_SetPrimarySaleRecipient is BaseTest {
    address public implementation;
    address public proxy;
    address internal caller;
    address internal _primarySaleRecipient;

    MyTokenERC20 internal tokenContract;

    event PrimarySaleRecipientUpdated(address indexed recipient);

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC20());

        caller = getActor(1);
        _primarySaleRecipient = getActor(2);

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = address(
            new TWProxy(
                implementation,
                abi.encodeCall(
                    TokenERC20.initialize,
                    (
                        deployer,
                        NAME,
                        SYMBOL,
                        CONTRACT_URI,
                        forwarders(),
                        saleRecipient,
                        platformFeeRecipient,
                        platformFeeBps
                    )
                )
            )
        );

        tokenContract = MyTokenERC20(proxy);
    }

    function test_setPrimarySaleRecipient_callerNotAuthorized() public {
        vm.prank(address(caller));
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(caller), 20),
                " is missing role ",
                Strings.toHexString(uint256(0), 32)
            )
        );
        tokenContract.setPrimarySaleRecipient(_primarySaleRecipient);
    }

    modifier whenCallerAuthorized() {
        vm.prank(deployer);
        tokenContract.grantRole(bytes32(0x00), caller);
        _;
    }

    function test_setPrimarySaleRecipient() public whenCallerAuthorized {
        vm.prank(address(caller));
        tokenContract.setPrimarySaleRecipient(_primarySaleRecipient);

        // get primary sale recipient info
        assertEq(tokenContract.primarySaleRecipient(), _primarySaleRecipient);
    }

    function test_setPrimarySaleRecipient_event() public whenCallerAuthorized {
        vm.prank(address(caller));
        vm.expectEmit(true, false, false, false);
        emit PrimarySaleRecipientUpdated(_primarySaleRecipient);
        tokenContract.setPrimarySaleRecipient(_primarySaleRecipient);
    }
}
