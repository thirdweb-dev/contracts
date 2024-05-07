// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";
import { IPlatformFee } from "contracts/extension/interface/IPlatformFee.sol";

contract MyTokenERC1155 is TokenERC1155 {}

contract TokenERC1155Test_SetPlatformFeeType is BaseTest {
    address public implementation;
    address public proxy;
    address internal caller;
    IPlatformFee.PlatformFeeType internal _newFeeType;

    MyTokenERC1155 internal tokenContract;

    event PlatformFeeTypeUpdated(IPlatformFee.PlatformFeeType feeType);

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
        _newFeeType = IPlatformFee.PlatformFeeType.Flat;
    }

    function test_setPlatformFeeType_callerNotAuthorized() public {
        vm.prank(address(caller));
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(caller), 20),
                " is missing role ",
                Strings.toHexString(uint256(0), 32)
            )
        );
        tokenContract.setPlatformFeeType(_newFeeType);
    }

    modifier whenCallerAuthorized() {
        vm.prank(deployer);
        tokenContract.grantRole(bytes32(0x00), caller);
        _;
    }

    function test_setPlatformFeeType() public whenCallerAuthorized {
        vm.prank(address(caller));
        tokenContract.setPlatformFeeType(_newFeeType);

        assertEq(uint8(tokenContract.getPlatformFeeType()), uint8(_newFeeType));
    }

    function test_setPlatformFeeType_event() public whenCallerAuthorized {
        vm.prank(address(caller));
        vm.expectEmit(false, false, false, true);
        emit PlatformFeeTypeUpdated(_newFeeType);
        tokenContract.setPlatformFeeType(_newFeeType);
    }
}
