// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC721 is TokenERC721 {}

contract TokenERC721Test_SetDefaultRoyaltyInfo is BaseTest {
    address public implementation;
    address public proxy;
    address internal caller;
    address internal defaultRoyaltyRecipient;
    uint256 internal defaultRoyaltyBps;

    MyTokenERC721 internal tokenContract;

    event DefaultRoyalty(address indexed newRoyaltyRecipient, uint256 newRoyaltyBps);

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC721());

        caller = getActor(1);
        defaultRoyaltyRecipient = getActor(2);

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
    }

    function test_setDefaultRoyaltyInfo_callerNotAuthorized() public {
        vm.prank(address(caller));
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(caller), 20),
                " is missing role ",
                Strings.toHexString(uint256(0), 32)
            )
        );
        tokenContract.setDefaultRoyaltyInfo(defaultRoyaltyRecipient, defaultRoyaltyBps);
    }

    modifier whenCallerAuthorized() {
        vm.prank(deployer);
        tokenContract.grantRole(bytes32(0x00), caller);
        _;
    }

    function test_setDefaultRoyaltyInfo_exceedMaxBps() public whenCallerAuthorized {
        defaultRoyaltyBps = 10_001;
        vm.prank(address(caller));
        vm.expectRevert("exceed royalty bps");
        tokenContract.setDefaultRoyaltyInfo(defaultRoyaltyRecipient, defaultRoyaltyBps);
    }

    modifier whenNotExceedMaxBps() {
        defaultRoyaltyBps = 500;
        _;
    }

    function test_setDefaultRoyaltyInfo() public whenCallerAuthorized whenNotExceedMaxBps {
        vm.prank(address(caller));
        tokenContract.setDefaultRoyaltyInfo(defaultRoyaltyRecipient, defaultRoyaltyBps);

        // get default royalty info
        (address _recipient, uint16 _royaltyBps) = tokenContract.getDefaultRoyaltyInfo();
        assertEq(_recipient, defaultRoyaltyRecipient);
        assertEq(_royaltyBps, uint16(defaultRoyaltyBps));

        // get royalty info for token
        uint256 tokenId = 0;
        (_recipient, _royaltyBps) = tokenContract.getRoyaltyInfoForToken(tokenId);
        assertEq(_recipient, defaultRoyaltyRecipient);
        assertEq(_royaltyBps, uint16(defaultRoyaltyBps));

        // royaltyInfo - ERC2981
        uint256 salePrice = 1000;
        (address _royaltyRecipient, uint256 _royaltyAmount) = tokenContract.royaltyInfo(tokenId, salePrice);
        assertEq(_royaltyRecipient, defaultRoyaltyRecipient);
        assertEq(_royaltyAmount, (salePrice * defaultRoyaltyBps) / 10_000);
    }

    function test_setDefaultRoyaltyInfo_event() public whenCallerAuthorized whenNotExceedMaxBps {
        vm.prank(address(caller));
        vm.expectEmit(true, false, false, true);
        emit DefaultRoyalty(defaultRoyaltyRecipient, defaultRoyaltyBps);
        tokenContract.setDefaultRoyaltyInfo(defaultRoyaltyRecipient, defaultRoyaltyBps);
    }
}
