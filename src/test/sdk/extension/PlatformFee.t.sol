// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { PlatformFee } from "contracts/extension/PlatformFee.sol";

contract MyPlatformFee is PlatformFee {
    bool condition;

    function setCondition(bool _condition) external {
        condition = _condition;
    }

    function _canSetPlatformFeeInfo() internal view override returns (bool) {
        return condition;
    }
}

contract ExtensionPlatformFee is DSTest, Test {
    MyPlatformFee internal ext;
    event PlatformFeeInfoUpdated(address indexed platformFeeRecipient, uint256 platformFeeBps);

    function setUp() public {
        ext = new MyPlatformFee();
    }

    function test_state_setPlatformFeeInfo() public {
        ext.setCondition(true);

        address _platformFeeRecipient = address(0x123);
        uint256 _platformFeeBps = 1000;
        ext.setPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);

        (address recipient, uint16 bps) = ext.getPlatformFeeInfo();
        assertEq(_platformFeeRecipient, recipient);
        assertEq(_platformFeeBps, bps);
    }

    function test_revert_setPlatformFeeInfo_ExceedsMaxBps() public {
        ext.setCondition(true);

        address _platformFeeRecipient = address(0x123);
        uint256 _platformFeeBps = 10001;

        vm.expectRevert(
            abi.encodeWithSelector(PlatformFee.PlatformFeeExceededMaxFeeBps.selector, 10_000, _platformFeeBps)
        );
        ext.setPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
    }

    function test_revert_setPlatformFeeInfo_NotAuthorized() public {
        vm.expectRevert(abi.encodeWithSelector(PlatformFee.PlatformFeeUnauthorized.selector));
        ext.setPlatformFeeInfo(address(1), 1000);
    }

    function test_event_platformFeeInfo() public {
        ext.setCondition(true);

        address _platformFeeRecipient = address(0x123);
        uint256 _platformFeeBps = 1000;

        vm.expectEmit(true, true, true, true);
        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);

        ext.setPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
    }
}
