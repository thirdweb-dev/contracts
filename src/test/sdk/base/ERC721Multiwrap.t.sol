// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import "./BaseUtilTest.sol";
import { ERC721Multiwrap } from "contracts/base/ERC721Multiwrap.sol";
import { CurrencyTransferLib } from "contracts/lib/CurrencyTransferLib.sol";
import { ITokenBundle } from "contracts/extension/interface/ITokenBundle.sol";

contract BaseERC721MultiwrapTest is BaseUtilTest {
    ERC721Multiwrap internal base;
    using Strings for uint256;

    Wallet internal tokenOwner;
    string internal uriForWrappedToken;
    ITokenBundle.Token[] internal wrappedContent;

    function setUp() public override {
        super.setUp();

        vm.prank(deployer);
        base = new ERC721Multiwrap(
            deployer,
            NAME,
            SYMBOL,
            royaltyRecipient,
            royaltyBps,
            CurrencyTransferLib.NATIVE_TOKEN
        );

        tokenOwner = getWallet();
        uriForWrappedToken = "ipfs://baseURI/";

        wrappedContent.push(
            ITokenBundle.Token({
                assetContract: address(erc20),
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 10 ether
            })
        );
        wrappedContent.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 0,
                totalAmount: 1
            })
        );
        wrappedContent.push(
            ITokenBundle.Token({
                assetContract: address(erc1155),
                tokenType: ITokenBundle.TokenType.ERC1155,
                tokenId: 0,
                totalAmount: 100
            })
        );

        erc20.mint(address(tokenOwner), 10 ether);
        erc721.mint(address(tokenOwner), 1);
        erc1155.mint(address(tokenOwner), 0, 100);

        tokenOwner.setAllowanceERC20(address(erc20), address(base), type(uint256).max);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(base), true);
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(base), true);

        vm.prank(deployer);
        base.grantRole(keccak256("MINTER_ROLE"), address(tokenOwner));
    }

    function getWrappedContents(uint256 _tokenId) public view returns (ITokenBundle.Token[] memory contents) {
        uint256 total = base.getTokenCountOfBundle(_tokenId);
        contents = new ITokenBundle.Token[](total);

        for (uint256 i = 0; i < total; i += 1) {
            contents[i] = base.getTokenOfBundle(_tokenId, i);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `wrap`
    //////////////////////////////////////////////////////////////*/

    function test_state_wrap() public {
        uint256 expectedIdForWrappedToken = base.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        base.wrap(wrappedContent, uriForWrappedToken, recipient);

        assertEq(expectedIdForWrappedToken + 1, base.nextTokenIdToMint());

        ITokenBundle.Token[] memory contentsOfWrappedToken = getWrappedContents(expectedIdForWrappedToken);
        assertEq(contentsOfWrappedToken.length, wrappedContent.length);
        for (uint256 i = 0; i < contentsOfWrappedToken.length; i += 1) {
            assertEq(contentsOfWrappedToken[i].assetContract, wrappedContent[i].assetContract);
            assertEq(uint256(contentsOfWrappedToken[i].tokenType), uint256(wrappedContent[i].tokenType));
            assertEq(contentsOfWrappedToken[i].tokenId, wrappedContent[i].tokenId);
            assertEq(contentsOfWrappedToken[i].totalAmount, wrappedContent[i].totalAmount);
        }

        assertEq(uriForWrappedToken, base.tokenURI(expectedIdForWrappedToken));
    }
}
