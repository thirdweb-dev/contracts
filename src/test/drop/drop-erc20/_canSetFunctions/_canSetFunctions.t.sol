// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC20 } from "contracts/prebuilts/drop/DropERC20.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import "../../../utils/BaseTest.sol";

contract HarnessDropERC20CanSet is DropERC20 {
    function canSetPlatformFeeInfo() external view returns (bool) {
        return _canSetPlatformFeeInfo();
    }

    function canSetPrimarySaleRecipient() external view returns (bool) {
        return _canSetPrimarySaleRecipient();
    }

    function canSetContractURI() external view returns (bool) {
        return _canSetContractURI();
    }

    function canSetClaimConditions() external view returns (bool) {
        return _canSetClaimConditions();
    }
}

contract DropERC20Test_canSet is BaseTest {
    address public dropImp;

    HarnessDropERC20CanSet public proxy;

    function setUp() public override {
        super.setUp();

        bytes memory initializeData = abi.encodeCall(
            DropERC20.initialize,
            (deployer, NAME, SYMBOL, CONTRACT_URI, forwarders(), saleRecipient, platformFeeRecipient, platformFeeBps)
        );

        dropImp = address(new HarnessDropERC20CanSet());
        proxy = HarnessDropERC20CanSet(address(new TWProxy(dropImp, initializeData)));
    }

    modifier callerHasDefaultAdminRole() {
        vm.startPrank(deployer);
        _;
    }

    modifier callerDoesNotHaveDefaultAdminRole() {
        _;
    }

    function test_canSetPlatformFee_returnTrue() public callerHasDefaultAdminRole {
        bool status = proxy.canSetPlatformFeeInfo();
        assertEq(status, true);
    }

    function test_canSetPlatformFee_returnFalse() public callerDoesNotHaveDefaultAdminRole {
        bool status = proxy.canSetPlatformFeeInfo();
        assertEq(status, false);
    }

    function test_canSetPrimarySaleRecipient_returnTrue() public callerHasDefaultAdminRole {
        bool status = proxy.canSetPrimarySaleRecipient();
        assertEq(status, true);
    }

    function test_canSetPrimarySaleRecipient_returnFalse() public callerDoesNotHaveDefaultAdminRole {
        bool status = proxy.canSetPrimarySaleRecipient();
        assertEq(status, false);
    }

    function test_canSetContractURI_returnTrue() public callerHasDefaultAdminRole {
        bool status = proxy.canSetContractURI();
        assertEq(status, true);
    }

    function test_canSetContractURI_returnFalse() public callerDoesNotHaveDefaultAdminRole {
        bool status = proxy.canSetContractURI();
        assertEq(status, false);
    }

    function test_canSetClaimConditions_returnTrue() public callerHasDefaultAdminRole {
        bool status = proxy.canSetClaimConditions();
        assertEq(status, true);
    }

    function test_canSetClaimConditions_returnFalse() public callerDoesNotHaveDefaultAdminRole {
        bool status = proxy.canSetClaimConditions();
        assertEq(status, false);
    }
}
