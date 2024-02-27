// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { Royalty, IRoyalty } from "contracts/extension/Royalty.sol";
import "../../ExtensionUtilTest.sol";

contract MyRoyalty is Royalty {
    address admin;

    constructor(address _admin) {
        admin = _admin;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {}

    function _canSetRoyaltyInfo() internal view override returns (bool) {
        return msg.sender == admin;
    }
}

contract Royalty_SetDefaultRoyaltyInfo is ExtensionUtilTest {
    MyRoyalty internal ext;
    address internal admin;
    address internal caller;
    address internal defaultRoyaltyRecipient;
    uint256 internal defaultRoyaltyBps;

    event DefaultRoyalty(address indexed newRoyaltyRecipient, uint256 newRoyaltyBps);

    function setUp() public override {
        super.setUp();

        admin = getActor(0);
        caller = getActor(1);
        defaultRoyaltyRecipient = getActor(2);

        ext = new MyRoyalty(address(admin));
    }

    function test_setDefaultRoyaltyInfo_callerNotAuthorized() public {
        vm.prank(address(caller));
        vm.expectRevert(abi.encodeWithSelector(Royalty.RoyaltyUnauthorized.selector));
        ext.setDefaultRoyaltyInfo(defaultRoyaltyRecipient, defaultRoyaltyBps);
    }

    modifier whenCallerAuthorized() {
        caller = admin;
        _;
    }

    function test_setDefaultRoyaltyInfo_exceedMaxBps() public whenCallerAuthorized {
        defaultRoyaltyBps = 10_001;
        vm.prank(address(caller));
        vm.expectRevert(abi.encodeWithSelector(Royalty.RoyaltyExceededMaxFeeBps.selector, 10_000, defaultRoyaltyBps));
        ext.setDefaultRoyaltyInfo(defaultRoyaltyRecipient, defaultRoyaltyBps);
    }

    modifier whenNotExceedMaxBps() {
        defaultRoyaltyBps = 500;
        _;
    }

    function test_setDefaultRoyaltyInfo() public whenCallerAuthorized whenNotExceedMaxBps {
        vm.prank(address(caller));
        ext.setDefaultRoyaltyInfo(defaultRoyaltyRecipient, defaultRoyaltyBps);

        // get default royalty info
        (address _recipient, uint16 _royaltyBps) = ext.getDefaultRoyaltyInfo();
        assertEq(_recipient, defaultRoyaltyRecipient);
        assertEq(_royaltyBps, uint16(defaultRoyaltyBps));

        // get royalty info for token
        uint256 tokenId = 0;
        (_recipient, _royaltyBps) = ext.getRoyaltyInfoForToken(tokenId);
        assertEq(_recipient, defaultRoyaltyRecipient);
        assertEq(_royaltyBps, uint16(defaultRoyaltyBps));

        // royaltyInfo - ERC2981
        uint256 salePrice = 1000;
        (address _royaltyRecipient, uint256 _royaltyAmount) = ext.royaltyInfo(tokenId, salePrice);
        assertEq(_royaltyRecipient, defaultRoyaltyRecipient);
        assertEq(_royaltyAmount, (salePrice * defaultRoyaltyBps) / 10_000);
    }

    function test_setDefaultRoyaltyInfo_event() public whenCallerAuthorized whenNotExceedMaxBps {
        vm.prank(address(caller));
        vm.expectEmit(true, false, false, true);
        emit DefaultRoyalty(defaultRoyaltyRecipient, defaultRoyaltyBps);
        ext.setDefaultRoyaltyInfo(defaultRoyaltyRecipient, defaultRoyaltyBps);
    }
}
