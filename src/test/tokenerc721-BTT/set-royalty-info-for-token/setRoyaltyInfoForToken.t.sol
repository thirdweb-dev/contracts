// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC721 is TokenERC721 {}

contract TokenERC721Test_SetRoyaltyInfoForToken is BaseTest {
    address public implementation;
    address public proxy;
    address internal caller;
    address internal defaultRoyaltyRecipient;
    uint256 internal defaultRoyaltyBps;

    MyTokenERC721 internal tokenContract;

    address internal royaltyRecipientForToken;
    uint256 internal royaltyBpsForToken;
    uint256 internal tokenId;

    event RoyaltyForToken(uint256 indexed tokenId, address indexed royaltyRecipient, uint256 royaltyBps);

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC721());

        caller = getActor(1);
        defaultRoyaltyRecipient = getActor(2);
        royaltyRecipientForToken = getActor(3);
        defaultRoyaltyBps = 500;
        tokenId = 1;

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = address(
            new TWProxy(
                implementation,
                abi.encodeCall(
                    TokenERC721.initialize,
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

        tokenContract = MyTokenERC721(proxy);

        vm.prank(deployer);
        tokenContract.setDefaultRoyaltyInfo(defaultRoyaltyRecipient, defaultRoyaltyBps);
    }

    function test_setRoyaltyInfoForToken_callerNotAuthorized() public {
        vm.prank(address(caller));
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(caller), 20),
                " is missing role ",
                Strings.toHexString(uint256(0), 32)
            )
        );
        tokenContract.setRoyaltyInfoForToken(tokenId, royaltyRecipientForToken, royaltyBpsForToken);
    }

    modifier whenCallerAuthorized() {
        vm.prank(deployer);
        tokenContract.grantRole(bytes32(0x00), caller);
        _;
    }

    function test_setRoyaltyInfoForToken_exceedMaxBps() public whenCallerAuthorized {
        royaltyBpsForToken = 10_001;
        vm.prank(address(caller));
        vm.expectRevert("exceed royalty bps");
        tokenContract.setRoyaltyInfoForToken(tokenId, royaltyRecipientForToken, royaltyBpsForToken);
    }

    modifier whenNotExceedMaxBps() {
        royaltyBpsForToken = 1000;
        _;
    }

    function test_setRoyaltyInfoForToken() public whenCallerAuthorized whenNotExceedMaxBps {
        vm.prank(address(caller));
        tokenContract.setRoyaltyInfoForToken(tokenId, royaltyRecipientForToken, royaltyBpsForToken);

        // get default royalty info
        (address _defaultRecipient, uint16 _defaultRoyaltyBps) = tokenContract.getDefaultRoyaltyInfo();
        assertEq(_defaultRecipient, defaultRoyaltyRecipient);
        assertEq(_defaultRoyaltyBps, uint16(defaultRoyaltyBps));

        // get royalty info for token
        (address _royaltyRecipientForToken, uint16 _royaltyBpsForToken) = tokenContract.getRoyaltyInfoForToken(tokenId);
        assertEq(_royaltyRecipientForToken, royaltyRecipientForToken);
        assertEq(_royaltyBpsForToken, uint16(royaltyBpsForToken));

        // royaltyInfo - ERC2981: calculate for default
        uint256 salePrice = 1000;
        (address _royaltyRecipient, uint256 _royaltyAmount) = tokenContract.royaltyInfo(0, salePrice);
        assertEq(_royaltyRecipient, defaultRoyaltyRecipient);
        assertEq(_royaltyAmount, (salePrice * defaultRoyaltyBps) / 10_000);

        // royaltyInfo - ERC2981: calculate for specific tokenId we set the royalty info for
        (_royaltyRecipient, _royaltyAmount) = tokenContract.royaltyInfo(tokenId, salePrice);
        assertEq(_royaltyRecipient, royaltyRecipientForToken);
        assertEq(_royaltyAmount, (salePrice * royaltyBpsForToken) / 10_000);
    }

    function test_setRoyaltyInfoForToken_event() public whenCallerAuthorized whenNotExceedMaxBps {
        vm.prank(address(caller));
        vm.expectEmit(true, true, false, true);
        emit RoyaltyForToken(tokenId, royaltyRecipientForToken, royaltyBpsForToken);
        tokenContract.setRoyaltyInfoForToken(tokenId, royaltyRecipientForToken, royaltyBpsForToken);
    }
}
