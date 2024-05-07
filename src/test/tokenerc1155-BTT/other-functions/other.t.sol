// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";
import { IStaking1155 } from "contracts/extension/interface/IStaking1155.sol";
import { IERC2981 } from "contracts/eip/interface/IERC2981.sol";

import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC1155 is TokenERC1155 {
    function canSetMetadata() public view returns (bool) {
        return _canSetMetadata();
    }

    function canFreezeMetadata() public view returns (bool) {
        return _canFreezeMetadata();
    }

    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        _beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setTotalSupply(uint256 _tokenId, uint256 _totalSupply) external {
        totalSupply[_tokenId] = _totalSupply;
    }
}

contract TokenERC1155Test_OtherFunctions is BaseTest {
    address public implementation;
    address public proxy;

    MyTokenERC1155 public tokenContract;
    address internal caller;

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC1155());
        caller = getActor(3);

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = address(
            new TWProxy(
                implementation,
                abi.encodeCall(
                    TokenERC1155.initialize,
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

        tokenContract = MyTokenERC1155(proxy);
    }

    function test_contractType() public {
        assertEq(tokenContract.contractType(), bytes32("TokenERC1155"));
    }

    function test_contractVersion() public {
        assertEq(tokenContract.contractVersion(), uint8(1));
    }

    function test_beforeTokenTransfer_restricted_notTransferRole() public {
        uint256[] memory ids;
        uint256[] memory amounts;

        vm.prank(deployer);
        tokenContract.revokeRole(keccak256("TRANSFER_ROLE"), address(0));
        vm.expectRevert("restricted to TRANSFER_ROLE holders.");
        tokenContract.beforeTokenTransfer(caller, caller, address(0x123), ids, amounts, "");
    }

    modifier whenTransferRole() {
        vm.prank(deployer);
        tokenContract.grantRole(keccak256("TRANSFER_ROLE"), caller);
        _;
    }

    function test_beforeTokenTransfer_restricted() public whenTransferRole {
        uint256[] memory ids;
        uint256[] memory amounts;
        tokenContract.beforeTokenTransfer(caller, caller, address(0x123), ids, amounts, "");
    }

    function test_beforeTokenTransfer_restricted_fromZero() public whenTransferRole {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        uint256 _initialSupply = 100;

        ids[0] = 1;
        amounts[0] = 10;
        tokenContract.setTotalSupply(ids[0], _initialSupply); // mock set supply

        tokenContract.beforeTokenTransfer(caller, address(0), address(0x123), ids, amounts, "");

        assertEq(tokenContract.totalSupply(ids[0]), amounts[0] + _initialSupply);
    }

    function test_beforeTokenTransfer_restricted_toZero() public whenTransferRole {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        uint256 _initialSupply = 100;

        ids[0] = 1;
        amounts[0] = 10;
        tokenContract.setTotalSupply(ids[0], _initialSupply); // mock set supply

        tokenContract.beforeTokenTransfer(caller, caller, address(0), ids, amounts, "");

        assertEq(tokenContract.totalSupply(ids[0]), _initialSupply - amounts[0]);
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
        assertTrue(tokenContract.supportsInterface(type(IERC1155Upgradeable).interfaceId));

        // false for other not supported interfaces
        assertFalse(tokenContract.supportsInterface(type(IStaking1155).interfaceId));
    }
}
