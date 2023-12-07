// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import "../../mocks/WETH9.sol";
import "../../mocks/MockERC20.sol";
import "../../mocks/MockERC721.sol";
import "../../mocks/MockERC1155.sol";

import { TokenBundle, ITokenBundle } from "contracts/extension/TokenBundle.sol";

contract MyTokenBundle is TokenBundle {
    function createBundle(Token[] calldata _tokensToBind, uint256 _bundleId) external {
        _createBundle(_tokensToBind, _bundleId);
    }

    function updateBundle(Token[] calldata _tokensToBind, uint256 _bundleId) external {
        _updateBundle(_tokensToBind, _bundleId);
    }

    function addTokenInBundle(Token memory _tokenToBind, uint256 _bundleId) external {
        _addTokenInBundle(_tokenToBind, _bundleId);
    }

    function updateTokenInBundle(Token memory _tokenToBind, uint256 _bundleId, uint256 _index) external {
        _updateTokenInBundle(_tokenToBind, _bundleId, _index);
    }

    function setUriOfBundle(string calldata _uri, uint256 _bundleId) external {
        _setUriOfBundle(_uri, _bundleId);
    }

    function deleteBundle(uint256 _bundleId) external {
        _deleteBundle(_bundleId);
    }
}

contract ExtensionTokenBundle is DSTest, Test {
    MyTokenBundle internal ext;

    MockERC20 public erc20;
    MockERC721 public erc721;
    MockERC1155 public erc1155;
    WETH9 public weth;

    ITokenBundle.Token[] internal bundleContent;

    function setUp() public {
        ext = new MyTokenBundle();

        erc20 = new MockERC20();
        erc721 = new MockERC721();
        erc1155 = new MockERC1155();
        weth = new WETH9();

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
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `createBundle`
    //////////////////////////////////////////////////////////////*/

    function test_state_createBundle() public {
        ext.createBundle(bundleContent, 0);

        uint256 tokenCountOfBundle = ext.getTokenCountOfBundle(0);
        assertEq(bundleContent.length, tokenCountOfBundle);

        for (uint256 i = 0; i < tokenCountOfBundle; i += 1) {
            ITokenBundle.Token memory tokenOfBundle = ext.getTokenOfBundle(0, i);
            assertEq(bundleContent[i].assetContract, tokenOfBundle.assetContract);
            assertEq(uint256(bundleContent[i].tokenType), uint256(tokenOfBundle.tokenType));
            assertEq(bundleContent[i].tokenId, tokenOfBundle.tokenId);
            assertEq(bundleContent[i].totalAmount, tokenOfBundle.totalAmount);
        }
    }

    function test_revert_createBundle_emptyBundle() public {
        ITokenBundle.Token[] memory emptyBundle;

        vm.expectRevert("!Tokens");
        ext.createBundle(emptyBundle, 0);
    }

    function test_revert_createBundle_existingBundleId() public {
        ext.createBundle(bundleContent, 0);

        vm.expectRevert("id exists");
        ext.createBundle(bundleContent, 0);
    }

    function test_revert_createBundle_tokenTypeMismatch() public {
        bundleContent.push(
            ITokenBundle.Token({
                assetContract: address(erc20),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 0,
                totalAmount: 0
            })
        );

        vm.expectRevert("!TokenType");
        ext.createBundle(bundleContent, 0);

        bundleContent.pop();
        bundleContent.push(
            ITokenBundle.Token({
                assetContract: address(erc20),
                tokenType: ITokenBundle.TokenType.ERC1155,
                tokenId: 0,
                totalAmount: 0
            })
        );

        vm.expectRevert("!TokenType");
        ext.createBundle(bundleContent, 0);

        bundleContent.pop();
        bundleContent.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 0
            })
        );

        vm.expectRevert("!TokenType");
        ext.createBundle(bundleContent, 0);

        bundleContent.pop();
        bundleContent.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC1155,
                tokenId: 0,
                totalAmount: 0
            })
        );

        vm.expectRevert("!TokenType");
        ext.createBundle(bundleContent, 0);

        bundleContent.pop();
        bundleContent.push(
            ITokenBundle.Token({
                assetContract: address(erc1155),
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 0
            })
        );

        vm.expectRevert("!TokenType");
        ext.createBundle(bundleContent, 0);

        bundleContent.pop();
        bundleContent.push(
            ITokenBundle.Token({
                assetContract: address(erc1155),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 0,
                totalAmount: 0
            })
        );

        vm.expectRevert("!TokenType");
        ext.createBundle(bundleContent, 0);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `updateBundle`
    //////////////////////////////////////////////////////////////*/

    function test_state_updateBundle() public {
        ext.createBundle(bundleContent, 0);

        bundleContent.push(
            ITokenBundle.Token({
                assetContract: address(erc1155),
                tokenType: ITokenBundle.TokenType.ERC1155,
                tokenId: 1,
                totalAmount: 200
            })
        );

        ext.updateBundle(bundleContent, 0);

        uint256 tokenCountOfBundle = ext.getTokenCountOfBundle(0);
        assertEq(bundleContent.length, tokenCountOfBundle);

        for (uint256 i = 0; i < tokenCountOfBundle; i += 1) {
            ITokenBundle.Token memory tokenOfBundle = ext.getTokenOfBundle(0, i);
            assertEq(bundleContent[i].assetContract, tokenOfBundle.assetContract);
            assertEq(uint256(bundleContent[i].tokenType), uint256(tokenOfBundle.tokenType));
            assertEq(bundleContent[i].tokenId, tokenOfBundle.tokenId);
            assertEq(bundleContent[i].totalAmount, tokenOfBundle.totalAmount);
        }

        bundleContent.pop();
        bundleContent.pop();
        ext.updateBundle(bundleContent, 0);

        tokenCountOfBundle = ext.getTokenCountOfBundle(0);
        assertEq(bundleContent.length, tokenCountOfBundle);

        for (uint256 i = 0; i < tokenCountOfBundle; i += 1) {
            ITokenBundle.Token memory tokenOfBundle = ext.getTokenOfBundle(0, i);
            assertEq(bundleContent[i].assetContract, tokenOfBundle.assetContract);
            assertEq(uint256(bundleContent[i].tokenType), uint256(tokenOfBundle.tokenType));
            assertEq(bundleContent[i].tokenId, tokenOfBundle.tokenId);
            assertEq(bundleContent[i].totalAmount, tokenOfBundle.totalAmount);
        }
    }

    function test_revert_updateBundle_emptyBundle() public {
        ext.createBundle(bundleContent, 0);

        ITokenBundle.Token[] memory emptyBundle;
        vm.expectRevert("!Tokens");
        ext.updateBundle(emptyBundle, 0);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `addTokenInBundle`
    //////////////////////////////////////////////////////////////*/

    function test_state_addTokenInBundle() public {
        ext.createBundle(bundleContent, 0);

        ITokenBundle.Token memory newToken = ITokenBundle.Token({
            assetContract: address(erc1155),
            tokenType: ITokenBundle.TokenType.ERC1155,
            tokenId: 1,
            totalAmount: 200
        });

        ext.addTokenInBundle(newToken, 0);

        uint256 tokenCountOfBundle = ext.getTokenCountOfBundle(0);
        assertEq(bundleContent.length + 1, tokenCountOfBundle);

        for (uint256 i = 0; i < tokenCountOfBundle - 1; i += 1) {
            ITokenBundle.Token memory tokenOfBundle_ = ext.getTokenOfBundle(0, i);
            assertEq(bundleContent[i].assetContract, tokenOfBundle_.assetContract);
            assertEq(uint256(bundleContent[i].tokenType), uint256(tokenOfBundle_.tokenType));
            assertEq(bundleContent[i].tokenId, tokenOfBundle_.tokenId);
            assertEq(bundleContent[i].totalAmount, tokenOfBundle_.totalAmount);
        }

        ITokenBundle.Token memory tokenOfBundle = ext.getTokenOfBundle(0, tokenCountOfBundle - 1);
        assertEq(newToken.assetContract, tokenOfBundle.assetContract);
        assertEq(uint256(newToken.tokenType), uint256(tokenOfBundle.tokenType));
        assertEq(newToken.tokenId, tokenOfBundle.tokenId);
        assertEq(newToken.totalAmount, tokenOfBundle.totalAmount);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `updateTokenInBundle`
    //////////////////////////////////////////////////////////////*/

    function test_state_updateTokenInBundle() public {
        ext.createBundle(bundleContent, 0);

        ITokenBundle.Token memory newToken = ITokenBundle.Token({
            assetContract: address(erc1155),
            tokenType: ITokenBundle.TokenType.ERC1155,
            tokenId: 1,
            totalAmount: 200
        });

        ext.updateTokenInBundle(newToken, 0, 1);

        uint256 tokenCountOfBundle = ext.getTokenCountOfBundle(0);
        assertEq(bundleContent.length, tokenCountOfBundle);

        ITokenBundle.Token memory tokenOfBundle = ext.getTokenOfBundle(0, 1);
        assertEq(newToken.assetContract, tokenOfBundle.assetContract);
        assertEq(uint256(newToken.tokenType), uint256(tokenOfBundle.tokenType));
        assertEq(newToken.tokenId, tokenOfBundle.tokenId);
        assertEq(newToken.totalAmount, tokenOfBundle.totalAmount);
    }

    function test_revert_updateTokenInBundle_indexDNE() public {
        ext.createBundle(bundleContent, 0);

        ITokenBundle.Token memory newToken = ITokenBundle.Token({
            assetContract: address(erc1155),
            tokenType: ITokenBundle.TokenType.ERC1155,
            tokenId: 1,
            totalAmount: 200
        });

        vm.expectRevert("index DNE");
        ext.updateTokenInBundle(newToken, 0, 3);
    }
}
