// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";
import { IStaking721 } from "contracts/extension/interface/IStaking721.sol";
import { IERC2981 } from "contracts/eip/interface/IERC2981.sol";

import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC721 is TokenERC721 {
    function canSetMetadata() public view returns (bool) {
        return _canSetMetadata();
    }

    function canFreezeMetadata() public view returns (bool) {
        return _canFreezeMetadata();
    }
}

contract TokenERC721Test_OtherFunctions is BaseTest {
    address public implementation;
    address public proxy;

    MyTokenERC721 public tokenContract;

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC721());

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

    function test_contractType() public {
        assertEq(tokenContract.contractType(), bytes32("TokenERC721"));
    }

    function test_contractVersion() public {
        assertEq(tokenContract.contractVersion(), uint8(1));
    }

    function test_canSetMetadata_notMetadataRole() public {
        assertFalse(tokenContract.canSetMetadata());
    }

    modifier whenMetadataRoleRole() {
        _;
    }

    function test_canSetMetadata() public whenMetadataRoleRole {
        vm.prank(deployer);
        assertTrue(tokenContract.canSetMetadata());
    }

    function test_canFreezeMetadata_notMetadataRole() public {
        assertFalse(tokenContract.canFreezeMetadata());
    }

    function test_canFreezeMetadata() public whenMetadataRoleRole {
        vm.prank(deployer);
        assertTrue(tokenContract.canFreezeMetadata());
    }

    function test_supportsInterface() public {
        assertTrue(tokenContract.supportsInterface(type(IERC2981).interfaceId));
        assertTrue(tokenContract.supportsInterface(type(IERC165).interfaceId));
        assertTrue(tokenContract.supportsInterface(type(IERC165Upgradeable).interfaceId));
        assertTrue(tokenContract.supportsInterface(type(IAccessControlEnumerableUpgradeable).interfaceId));
        assertTrue(tokenContract.supportsInterface(type(IAccessControlUpgradeable).interfaceId));
        assertTrue(tokenContract.supportsInterface(type(IERC721EnumerableUpgradeable).interfaceId));
        assertTrue(tokenContract.supportsInterface(type(IERC721Upgradeable).interfaceId));

        // false for other not supported interfaces
        assertFalse(tokenContract.supportsInterface(type(IStaking721).interfaceId));
    }
}
