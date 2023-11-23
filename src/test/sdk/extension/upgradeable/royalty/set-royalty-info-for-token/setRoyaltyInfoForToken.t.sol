// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { Royalty, IRoyalty } from "contracts/extension/upgradeable/Royalty.sol";
import "../../../ExtensionUtilTest.sol";

contract MyRoyaltyUpg is Royalty {
    address admin;

    constructor(address _admin) {
        admin = _admin;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {}

    function _canSetRoyaltyInfo() internal view override returns (bool) {
        return msg.sender == admin;
    }
}

contract UpgradeableRoyalty_SetRoyaltyInfoForToken is ExtensionUtilTest {
    MyRoyaltyUpg internal ext;
    address internal admin;
    address internal caller;
    address internal defaultRoyaltyRecipient;
    uint256 internal defaultRoyaltyBps;

    address internal royaltyRecipientForToken;
    uint256 internal royaltyBpsForToken;
    uint256 internal tokenId;

    event RoyaltyForToken(uint256 indexed tokenId, address indexed royaltyRecipient, uint256 royaltyBps);

    function setUp() public override {
        super.setUp();

        admin = getActor(0);
        caller = getActor(1);
        defaultRoyaltyRecipient = getActor(2);
        royaltyRecipientForToken = getActor(3);
        defaultRoyaltyBps = 500;
        tokenId = 1;

        ext = new MyRoyaltyUpg(address(admin));

        vm.prank(address(admin));
        ext.setDefaultRoyaltyInfo(defaultRoyaltyRecipient, defaultRoyaltyBps);
    }

    function test_setRoyaltyInfoForToken_callerNotAuthorized() public {
        vm.prank(address(caller));
        vm.expectRevert("Not authorized");
        ext.setRoyaltyInfoForToken(tokenId, royaltyRecipientForToken, royaltyBpsForToken);
    }

    modifier whenCallerAuthorized() {
        caller = admin;
        _;
    }

    function test_setRoyaltyInfoForToken_exceedMaxBps() public whenCallerAuthorized {
        royaltyBpsForToken = 10_001;
        vm.prank(address(caller));
        vm.expectRevert("Exceeds max bps");
        ext.setRoyaltyInfoForToken(tokenId, royaltyRecipientForToken, royaltyBpsForToken);
    }

    modifier whenNotExceedMaxBps() {
        royaltyBpsForToken = 1000;
        _;
    }

    function test_setRoyaltyInfoForToken() public whenCallerAuthorized whenNotExceedMaxBps {
        vm.prank(address(caller));
        ext.setRoyaltyInfoForToken(tokenId, royaltyRecipientForToken, royaltyBpsForToken);

        // get default royalty info
        (address _defaultRecipient, uint16 _defaultRoyaltyBps) = ext.getDefaultRoyaltyInfo();
        assertEq(_defaultRecipient, defaultRoyaltyRecipient);
        assertEq(_defaultRoyaltyBps, uint16(defaultRoyaltyBps));

        // get royalty info for token
        (address _royaltyRecipientForToken, uint16 _royaltyBpsForToken) = ext.getRoyaltyInfoForToken(tokenId);
        assertEq(_royaltyRecipientForToken, royaltyRecipientForToken);
        assertEq(_royaltyBpsForToken, uint16(royaltyBpsForToken));

        // royaltyInfo - ERC2981: calculate for default
        uint256 salePrice = 1000;
        (address _royaltyRecipient, uint256 _royaltyAmount) = ext.royaltyInfo(0, salePrice);
        assertEq(_royaltyRecipient, defaultRoyaltyRecipient);
        assertEq(_royaltyAmount, (salePrice * defaultRoyaltyBps) / 10_000);

        // royaltyInfo - ERC2981: calculate for specific tokenId we set the royalty info for
        (_royaltyRecipient, _royaltyAmount) = ext.royaltyInfo(tokenId, salePrice);
        assertEq(_royaltyRecipient, royaltyRecipientForToken);
        assertEq(_royaltyAmount, (salePrice * royaltyBpsForToken) / 10_000);
    }

    function test_setRoyaltyInfoForToken_event() public whenCallerAuthorized whenNotExceedMaxBps {
        vm.prank(address(caller));
        vm.expectEmit(true, true, false, true);
        emit RoyaltyForToken(tokenId, royaltyRecipientForToken, royaltyBpsForToken);
        ext.setRoyaltyInfoForToken(tokenId, royaltyRecipientForToken, royaltyBpsForToken);
    }
}
