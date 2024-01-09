// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC1155 is TokenERC1155 {}

contract TokenERC1155Test_SetFlatPlatformFeeInfo is BaseTest {
    address public implementation;
    address public proxy;
    address internal caller;
    address internal _platformFeeRecipient;
    uint256 internal _flatFee;

    MyTokenERC1155 internal tokenContract;

    event FlatPlatformFeeUpdated(address platformFeeRecipient, uint256 flatFee);

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC1155());

        caller = getActor(1);
        _platformFeeRecipient = getActor(2);

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
        _flatFee = 25;
    }

    function test_setFlatPlatformFeeInfo_callerNotAuthorized() public {
        vm.prank(address(caller));
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(caller), 20),
                " is missing role ",
                Strings.toHexString(uint256(0), 32)
            )
        );
        tokenContract.setFlatPlatformFeeInfo(_platformFeeRecipient, _flatFee);
    }

    modifier whenCallerAuthorized() {
        vm.prank(deployer);
        tokenContract.grantRole(bytes32(0x00), caller);
        _;
    }

    function test_setFlatPlatformFeeInfo() public whenCallerAuthorized {
        vm.prank(address(caller));
        tokenContract.setFlatPlatformFeeInfo(_platformFeeRecipient, _flatFee);

        // get platform fee info
        (address _recipient, uint256 _fee) = tokenContract.getFlatPlatformFeeInfo();
        assertEq(_recipient, _platformFeeRecipient);
        assertEq(_fee, _flatFee);
        assertEq(tokenContract.platformFeeRecipient(), _platformFeeRecipient);
    }

    function test_setFlatPlatformFeeInfo_event() public whenCallerAuthorized {
        vm.prank(address(caller));
        vm.expectEmit(false, false, false, true);
        emit FlatPlatformFeeUpdated(_platformFeeRecipient, _flatFee);
        tokenContract.setFlatPlatformFeeInfo(_platformFeeRecipient, _flatFee);
    }
}
