// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC20 } from "contracts/prebuilts/drop/DropERC20.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import "../../../utils/BaseTest.sol";

contract HarnessDropERC20Misc is DropERC20 {
    bytes32 private transferRole = keccak256("TRANSFER_ROLE");

    function msgData() public view returns (bytes memory) {
        return _msgData();
    }

    function transferTokensOnClaim(address _to, uint256 _quantityBeingClaimed) public returns (uint256) {
        return _transferTokensOnClaim(_to, _quantityBeingClaimed);
    }

    function beforeTokenTransfer(address from, address to, uint256 amount) public {
        _beforeTokenTransfer(from, to, amount);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }

    function hasTransferRole(address _account) public view returns (bool) {
        return hasRole(transferRole, _account);
    }
}

contract DropERC20Test_misc is BaseTest {
    address public dropImp;
    HarnessDropERC20Misc public proxy;

    function setUp() public override {
        super.setUp();

        bytes memory initializeData = abi.encodeCall(
            DropERC20.initialize,
            (deployer, NAME, SYMBOL, CONTRACT_URI, forwarders(), saleRecipient, platformFeeRecipient, platformFeeBps)
        );

        dropImp = address(new HarnessDropERC20Misc());
        proxy = HarnessDropERC20Misc(address(new TWProxy(dropImp, initializeData)));
    }

    function test_contractType_returnValue() public {
        assertEq(proxy.contractType(), "DropERC20");
    }

    function test_contractVersion_returnValue() public {
        assertEq(proxy.contractVersion(), uint8(4));
    }

    function test_msgData_returnValue() public {
        bytes memory msgData = proxy.msgData();
        bytes4 expectedData = proxy.msgData.selector;
        assertEq(bytes4(msgData), expectedData);
    }

    function test_state_transferTokensOnClaim() public {
        uint256 initialBalance = proxy.balanceOf(deployer);
        uint256 quantityBeingClaimed = 1;
        proxy.transferTokensOnClaim(deployer, quantityBeingClaimed);
        assertEq(proxy.balanceOf(deployer), initialBalance + quantityBeingClaimed);
    }

    function test_returnValue_transferTokensOnClaim() public {
        uint256 quantityBeingClaimed = 1;
        uint256 returnValue = proxy.transferTokensOnClaim(deployer, quantityBeingClaimed);
        assertEq(returnValue, 0);
    }

    function test_beforeTokenTransfer_revert_addressZeroNoTransferRole() public {
        vm.prank(deployer);
        proxy.revokeRole(keccak256("TRANSFER_ROLE"), address(0));
        vm.expectRevert("transfers restricted.");
        proxy.beforeTokenTransfer(address(0x01), address(0x02), 1);
    }

    function test_beforeTokenTransfer_doesNotRevert_addressZeroNoTransferRole_burnMint() public {
        vm.prank(deployer);
        proxy.revokeRole(keccak256("TRANSFER_ROLE"), address(0));
        proxy.beforeTokenTransfer(address(0), address(0x02), 1);
        proxy.beforeTokenTransfer(address(0x01), address(0), 1);
    }

    function test_state_mint() public {
        uint256 initialBalance = proxy.balanceOf(deployer);
        uint256 amount = 1;
        proxy.mint(deployer, amount);
        assertEq(proxy.balanceOf(deployer), initialBalance + amount);
    }

    function test_state_burn() public {
        proxy.mint(deployer, 1);
        uint256 initialBalance = proxy.balanceOf(deployer);
        uint256 amount = 1;
        proxy.burn(deployer, amount);
        assertEq(proxy.balanceOf(deployer), initialBalance - amount);
    }

    function test_transfer_drop() public {
        //deal erc20 drop to address(0x1)
        deal(address(proxy), address(0x1), 1);
        vm.prank(address(0x1));
        proxy.transfer(address(0x2), 1);
        assertEq(proxy.balanceOf(address(0x2)), 1);
    }
}
