// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";
import { IStaking20 } from "contracts/extension/interface/IStaking20.sol";

import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC20 is TokenERC20 {
    function beforeTokenTransfer(address from, address to, uint256 amount) external {
        _beforeTokenTransfer(from, to, amount);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}

contract TokenERC20Test_OtherFunctions is BaseTest {
    address public implementation;
    address public proxy;

    MyTokenERC20 public tokenContract;
    address internal caller;

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC20());
        caller = getActor(3);

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = address(
            new TWProxy(
                implementation,
                abi.encodeCall(
                    TokenERC20.initialize,
                    (
                        deployer,
                        NAME,
                        SYMBOL,
                        CONTRACT_URI,
                        forwarders(),
                        saleRecipient,
                        platformFeeRecipient,
                        platformFeeBps
                    )
                )
            )
        );

        tokenContract = MyTokenERC20(proxy);
    }

    function test_contractType() public {
        assertEq(tokenContract.contractType(), bytes32("TokenERC20"));
    }

    function test_contractVersion() public {
        assertEq(tokenContract.contractVersion(), uint8(1));
    }

    function test_beforeTokenTransfer_restricted_notTransferRole() public {
        vm.prank(deployer);
        tokenContract.revokeRole(keccak256("TRANSFER_ROLE"), address(0));
        vm.expectRevert("transfers restricted.");
        tokenContract.beforeTokenTransfer(caller, address(0x123), 100);
    }

    modifier whenTransferRole() {
        vm.prank(deployer);
        tokenContract.grantRole(keccak256("TRANSFER_ROLE"), caller);
        _;
    }

    function test_beforeTokenTransfer_restricted() public whenTransferRole {
        tokenContract.beforeTokenTransfer(caller, address(0x123), 100);
    }

    function test_mint() public {
        tokenContract.mint(caller, 100);
        assertEq(tokenContract.balanceOf(caller), 100);
    }

    function test_burn() public {
        tokenContract.mint(caller, 100);
        assertEq(tokenContract.balanceOf(caller), 100);

        tokenContract.burn(caller, 60);
        assertEq(tokenContract.balanceOf(caller), 40);
    }
}
