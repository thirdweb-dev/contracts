// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { BurnToClaim, IBurnToClaim } from "contracts/extension/upgradeable/BurnToClaim.sol";
import "../../../ExtensionUtilTest.sol";

contract MyBurnToClaimUpg is BurnToClaim {
    bool condition;
    address admin;

    constructor(address _admin) {
        admin = _admin;
    }

    function _canSetBurnToClaim() internal view override returns (bool) {
        return msg.sender == admin;
    }
}

contract UpgradeableBurnToClaim_SetBurnToClaimInfo is ExtensionUtilTest {
    MyBurnToClaimUpg internal ext;
    address internal admin;
    address internal caller;
    IBurnToClaim.BurnToClaimInfo internal info;

    function setUp() public override {
        super.setUp();

        admin = getActor(0);
        caller = getActor(1);

        ext = new MyBurnToClaimUpg(address(admin));
        info = IBurnToClaim.BurnToClaimInfo({
            originContractAddress: address(0),
            tokenType: IBurnToClaim.TokenType.ERC721,
            tokenId: 0,
            mintPriceForNewToken: 0,
            currency: address(0)
        });
    }

    function test_setBurnToClaimInfo_callerNotAuthorized() public {
        vm.prank(address(caller));
        vm.expectRevert("Not authorized.");
        ext.setBurnToClaimInfo(info);
    }

    modifier whenCallerAuthorized() {
        caller = admin;
        _;
    }

    function test_setBurnToClaimInfo_invalidOriginContract_addressZero() public whenCallerAuthorized {
        vm.prank(address(caller));
        vm.expectRevert("Origin contract not set.");
        ext.setBurnToClaimInfo(info);
    }

    modifier whenValidOriginContract() {
        info.originContractAddress = address(erc721);
        _;
    }

    function test_setBurnToClaimInfo_invalidCurrency_addressZero() public whenCallerAuthorized whenValidOriginContract {
        vm.prank(address(caller));
        vm.expectRevert("Currency not set.");
        ext.setBurnToClaimInfo(info);
    }

    modifier whenValidCurrency() {
        info.currency = address(erc20);
        _;
    }

    function test_setBurnToClaimInfo() public whenCallerAuthorized whenValidOriginContract whenValidCurrency {
        vm.prank(address(caller));
        ext.setBurnToClaimInfo(info);

        IBurnToClaim.BurnToClaimInfo memory _info = ext.getBurnToClaimInfo();

        assertEq(_info.originContractAddress, info.originContractAddress);
        assertEq(_info.currency, info.currency);
    }
}
