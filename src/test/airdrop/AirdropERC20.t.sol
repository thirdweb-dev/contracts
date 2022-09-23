// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/airdrop/AirdropERC20.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC20Test is BaseTest {
    AirdropERC20 internal drop;

    Wallet internal tokenOwner;

    IAirdropERC20.AirdropContent[] internal _contents;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC20(getContract("AirdropERC20"));

        tokenOwner = getWallet();

        erc20.mint(address(tokenOwner), 10_000 ether);
        tokenOwner.setAllowanceERC20(address(erc20), address(drop), type(uint256).max);

        for (uint256 i = 0; i < 1000; i++) {
            _contents.push(
                IAirdropERC20.AirdropContent({
                    tokenAddress: address(erc20),
                    tokenOwner: address(tokenOwner),
                    recipient: getActor(uint160(i)),
                    amount: 10 ether
                })
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `createPack`
    //////////////////////////////////////////////////////////////*/

    function test_state_airdrop() public {
        vm.startPrank(deployer);
        drop.addAirdropRecipients(_contents);
        drop.airdrop(_contents.length);
        vm.stopPrank();

        for (uint256 i = 0; i < 1000; i++) {
            assertEq(erc20.balanceOf(_contents[i].recipient), _contents[i].amount);
        }
        assertEq(erc20.balanceOf(address(tokenOwner)), 0);
    }

    function test_state_airdrop_nativeToken() public {
        vm.deal(deployer, 10_000 ether);

        uint256 balBefore = deployer.balance;

        for (uint256 i = 0; i < 1000; i++) {
            _contents[i].tokenAddress = NATIVE_TOKEN;
        }

        vm.startPrank(deployer);
        drop.addAirdropRecipients{ value: 10_000 ether }(_contents);
        drop.airdrop(_contents.length);
        vm.stopPrank();

        for (uint256 i = 0; i < 1000; i++) {
            assertEq(_contents[i].recipient.balance, _contents[i].amount);
        }
        assertEq(deployer.balance, balBefore - 10_000 ether);
    }

    function test_revert_airdrop_incorrectNativeTokenAmt() public {
        vm.deal(deployer, 11_000 ether);

        uint256 incorrectAmt = 10_000 ether + 1;

        for (uint256 i = 0; i < 1000; i++) {
            _contents[i].tokenAddress = NATIVE_TOKEN;
        }

        vm.prank(deployer);
        vm.expectRevert("Incorrect native token amount");
        drop.addAirdropRecipients{ value: incorrectAmt }(_contents);
    }

    function test_revert_airdrop_notAdmin() public {
        vm.prank(address(25));
        vm.expectRevert(
            abi.encodePacked(
                "Permissions: account ",
                TWStrings.toHexString(uint160(address(25)), 20),
                " is missing role ",
                TWStrings.toHexString(uint256(0x00), 32)
            )
        );
        drop.addAirdropRecipients(_contents);
    }

    function test_revert_airdrop_notApproved() public {
        tokenOwner.setAllowanceERC20(address(erc20), address(drop), 0);

        vm.startPrank(deployer);
        drop.addAirdropRecipients(_contents);
        vm.expectRevert("ERC20: insufficient allowance");
        drop.airdrop(_contents.length);
        vm.stopPrank();
    }
}
