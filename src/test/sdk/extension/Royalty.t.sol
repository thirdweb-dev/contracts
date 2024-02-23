// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { Royalty } from "contracts/extension/Royalty.sol";

contract MyRoyalty is Royalty {
    bool condition;

    function setCondition(bool _condition) external {
        condition = _condition;
    }

    function _canSetRoyaltyInfo() internal view override returns (bool) {
        return condition;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == 0x01ffc9a7;
    }
}

contract ExtensionRoyaltyTest is DSTest, Test {
    MyRoyalty internal ext;
    event DefaultRoyalty(address indexed newRoyaltyRecipient, uint256 newRoyaltyBps);
    event RoyaltyForToken(uint256 indexed tokenId, address indexed royaltyRecipient, uint256 royaltyBps);

    function setUp() public {
        ext = new MyRoyalty();
    }

    function test_state_setDefaultRoyaltyInfo() public {
        ext.setCondition(true);

        address _royaltyRecipient = address(0x123);
        uint256 _royaltyBps = 1000;
        ext.setDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);

        (address royaltyRecipient, uint256 royaltyBps) = ext.getDefaultRoyaltyInfo();
        assertEq(royaltyRecipient, _royaltyRecipient);
        assertEq(royaltyBps, _royaltyBps);

        (address receiver, uint256 royaltyAmount) = ext.royaltyInfo(0, 100);
        assertEq(receiver, _royaltyRecipient);
        assertEq(royaltyAmount, (100 * 1000) / 10_000);
    }

    function test_revert_setDefaultRoyaltyInfo_ExceedsMaxBps() public {
        ext.setCondition(true);

        address _royaltyRecipient = address(0x123);
        uint256 _royaltyBps = 10001;

        vm.expectRevert(abi.encodeWithSelector(Royalty.RoyaltyExceededMaxFeeBps.selector, 10_000, _royaltyBps));
        ext.setDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }

    function test_state_setRoyaltyInfoForToken() public {
        ext.setCondition(true);

        uint256 _tokenId = 1;
        address _recipient = address(0x123);
        uint256 _bps = 1000;
        ext.setRoyaltyInfoForToken(_tokenId, _recipient, _bps);

        (address receiver, uint256 royaltyAmount) = ext.royaltyInfo(_tokenId, 100);
        assertEq(receiver, _recipient);
        assertEq(royaltyAmount, (100 * 1000) / 10_000);
    }

    function test_revert_setRoyaltyInfo_NotAuthorized() public {
        vm.expectRevert(abi.encodeWithSelector(Royalty.RoyaltyUnauthorized.selector));
        ext.setRoyaltyInfoForToken(0, address(1), 1000);
    }

    function test_revert_setRoyaltyInfoForToken_ExceedsMaxBps() public {
        ext.setCondition(true);

        uint256 _tokenId = 1;
        address _recipient = address(0x123);
        uint256 _bps = 10001;

        vm.expectRevert(abi.encodeWithSelector(Royalty.RoyaltyExceededMaxFeeBps.selector, 10_000, _bps));
        ext.setRoyaltyInfoForToken(_tokenId, _recipient, _bps);
    }

    function test_event_defaultRoyalty() public {
        ext.setCondition(true);

        address _royaltyRecipient = address(0x123);
        uint256 _royaltyBps = 1000;

        vm.expectEmit(true, true, true, true);
        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);

        ext.setDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }

    function test_event_royaltyForToken() public {
        ext.setCondition(true);

        uint256 _tokenId = 1;
        address _recipient = address(0x123);
        uint256 _bps = 1000;

        vm.expectEmit(true, true, true, true);
        emit RoyaltyForToken(_tokenId, _recipient, _bps);

        ext.setRoyaltyInfoForToken(_tokenId, _recipient, _bps);
    }
}
