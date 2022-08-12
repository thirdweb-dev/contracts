// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import "../../mocks/WETH9.sol";
import "../../mocks/MockERC20.sol";
import "../../mocks/MockERC721.sol";
import "../../mocks/MockERC1155.sol";
import "../../utils/Wallet.sol";

import { TokenStore, TokenBundle, ITokenBundle, CurrencyTransferLib } from "contracts/extension/TokenStore.sol";

contract MyTokenStore is TokenStore {
    constructor(address _nativeTokenWrapper) TokenStore(_nativeTokenWrapper) {}

    receive() external payable {}

    function storeTokens(
        address _tokenOwner,
        Token[] calldata _tokens,
        string calldata _uriForTokens,
        uint256 _idForTokens
    ) external {
        _storeTokens(_tokenOwner, _tokens, _uriForTokens, _idForTokens);
    }

    function releaseTokens(address _recipient, uint256 _idForContent) external {
        _releaseTokens(_recipient, _idForContent);
    }
}

contract ExtensionTokenStore is DSTest, Test {
    MyTokenStore internal ext;

    MockERC20 public erc20;
    MockERC721 public erc721;
    MockERC1155 public erc1155;
    WETH9 public weth;

    ITokenBundle.Token[] internal bundleContent;

    Wallet internal tokenOwner;

    function setUp() public {
        ext = new MyTokenStore(CurrencyTransferLib.NATIVE_TOKEN);

        erc20 = new MockERC20();
        erc721 = new MockERC721();
        erc1155 = new MockERC1155();
        weth = new WETH9();

        tokenOwner = new Wallet();

        bundleContent.push(
            ITokenBundle.Token({
                assetContract: address(erc20),
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 10 ether
            })
        );
        bundleContent.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 0,
                totalAmount: 1
            })
        );
        bundleContent.push(
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

        tokenOwner.setAllowanceERC20(address(erc20), address(ext), type(uint256).max);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(ext), true);
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(ext), true);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `storeTokens`
    //////////////////////////////////////////////////////////////*/

    function test_balances_storeTokens() public {
        assertEq(erc20.balanceOf(address(tokenOwner)), 10 ether);
        assertEq(erc20.balanceOf(address(ext)), 0);

        assertEq(erc721.ownerOf(0), address(tokenOwner));

        assertEq(erc1155.balanceOf(address(tokenOwner), 0), 100);
        assertEq(erc1155.balanceOf(address(ext), 0), 0);

        vm.prank(address(tokenOwner));
        ext.storeTokens(address(tokenOwner), bundleContent, "", 0);

        assertEq(erc20.balanceOf(address(tokenOwner)), 0);
        assertEq(erc20.balanceOf(address(ext)), 10 ether);

        assertEq(erc721.ownerOf(0), address(ext));

        assertEq(erc1155.balanceOf(address(tokenOwner), 0), 0);
        assertEq(erc1155.balanceOf(address(ext), 0), 100);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `releaseTokens`
    //////////////////////////////////////////////////////////////*/

    function test_balances_releaseTokens() public {
        vm.prank(address(tokenOwner));
        ext.storeTokens(address(tokenOwner), bundleContent, "", 0);

        assertEq(erc20.balanceOf(address(tokenOwner)), 0);
        assertEq(erc20.balanceOf(address(ext)), 10 ether);

        assertEq(erc721.ownerOf(0), address(ext));

        assertEq(erc1155.balanceOf(address(tokenOwner), 0), 0);
        assertEq(erc1155.balanceOf(address(ext), 0), 100);

        ext.releaseTokens(address(0x345), 0);

        assertEq(erc20.balanceOf(address(0x345)), 10 ether);
        assertEq(erc20.balanceOf(address(ext)), 0);

        assertEq(erc721.ownerOf(0), address(0x345));

        assertEq(erc1155.balanceOf(address(0x345), 0), 100);
        assertEq(erc1155.balanceOf(address(ext), 0), 0);
    }
}
