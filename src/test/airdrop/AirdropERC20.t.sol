// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { AirdropERC20, IAirdropERC20 } from "contracts/prebuilts/unaudited/airdrop/AirdropERC20.sol";
import { CurrencyTransferLib } from "contracts/lib/CurrencyTransferLib.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

import "../mocks/MockERC20NonCompliant.sol";

contract AirdropERC20Test is BaseTest {
    AirdropERC20 internal drop;

    Wallet internal tokenOwner;

    IAirdropERC20.AirdropContent[] internal _contentsOne;
    IAirdropERC20.AirdropContent[] internal _contentsTwo;

    uint256 countOne;
    uint256 countTwo;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC20(getContract("AirdropERC20"));

        tokenOwner = getWallet();

        erc20.mint(address(tokenOwner), 10_000 ether);
        tokenOwner.setAllowanceERC20(address(erc20), address(drop), type(uint256).max);

        countOne = 1000;
        countTwo = 200;

        for (uint256 i = 0; i < countOne; i++) {
            _contentsOne.push(IAirdropERC20.AirdropContent({ recipient: getActor(uint160(i)), amount: 10 ether }));
        }

        for (uint256 i = countOne; i < countOne + countTwo; i++) {
            _contentsTwo.push(IAirdropERC20.AirdropContent({ recipient: getActor(uint160(i)), amount: 10 ether }));
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: stateless airdrop
    //////////////////////////////////////////////////////////////*/

    function test_state_airdrop() public {
        vm.prank(deployer);
        drop.airdropERC20(address(erc20), address(tokenOwner), _contentsOne);

        for (uint256 i = 0; i < countOne; i++) {
            assertEq(erc20.balanceOf(_contentsOne[i].recipient), _contentsOne[i].amount);
        }
        assertEq(erc20.balanceOf(address(tokenOwner)), 0);
    }

    function test_revert_airdrop_insufficientValue() public {
        vm.prank(deployer);
        vm.expectRevert("Insufficient native token amount");
        drop.airdropERC20(CurrencyTransferLib.NATIVE_TOKEN, address(tokenOwner), _contentsOne);
    }

    function test_revert_airdrop_notOwner() public {
        vm.startPrank(address(25));
        vm.expectRevert("Not authorized.");
        drop.airdropERC20(address(erc20), address(tokenOwner), _contentsOne);
        vm.stopPrank();
    }

    function test_revert_airdrop_notApproved() public {
        tokenOwner.setAllowanceERC20(address(erc20), address(drop), 0);

        vm.startPrank(deployer);
        vm.expectRevert("Not balance or allowance");
        drop.airdropERC20(address(erc20), address(tokenOwner), _contentsOne);
        vm.stopPrank();
    }
}

contract AirdropERC20AuditTest is BaseTest {
    AirdropERC20 internal drop;

    Wallet internal tokenOwner;

    IAirdropERC20.AirdropContent[] internal _contentsOne;
    IAirdropERC20.AirdropContent[] internal _contentsTwo;

    uint256 countOne;
    uint256 countTwo;

    MockERC20NonCompliant public erc20_nonCompliant;

    function setUp() public override {
        super.setUp();

        erc20_nonCompliant = new MockERC20NonCompliant();
        drop = AirdropERC20(getContract("AirdropERC20"));

        tokenOwner = getWallet();

        erc20_nonCompliant.mint(address(tokenOwner), 10_000 ether);
        tokenOwner.setAllowanceERC20(address(erc20_nonCompliant), address(drop), type(uint256).max);

        countOne = 1000;
        countTwo = 200;

        for (uint256 i = 0; i < countOne; i++) {
            _contentsOne.push(IAirdropERC20.AirdropContent({ recipient: getActor(uint160(i)), amount: 10 ether }));
        }

        for (uint256 i = countOne; i < countOne + countTwo; i++) {
            _contentsTwo.push(IAirdropERC20.AirdropContent({ recipient: getActor(uint160(i)), amount: 10 ether }));
        }
    }

    function test_process_payments_with_non_compliant_token() public {
        vm.prank(deployer);
        drop.airdropERC20(address(erc20_nonCompliant), address(tokenOwner), _contentsOne);

        // check balances after airdrop
        for (uint256 i = 0; i < countOne; i++) {
            assertEq(erc20_nonCompliant.balanceOf(_contentsOne[i].recipient), _contentsOne[i].amount);
        }
        assertEq(erc20_nonCompliant.balanceOf(address(tokenOwner)), 0);
    }
}

contract AirdropERC20GasTest is BaseTest {
    AirdropERC20 internal drop;

    Wallet internal tokenOwner;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC20(getContract("AirdropERC20"));

        tokenOwner = getWallet();

        erc20.mint(address(tokenOwner), 10_000 ether);
        tokenOwner.setAllowanceERC20(address(erc20), address(drop), type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: gas benchmarks, etc.
    //////////////////////////////////////////////////////////////*/

    function test_transferNativeToken_toEOA() public {
        vm.prank(address(tokenOwner));
        (bool success, bytes memory data) = address(0x123).call{ value: 1 ether }("");

        // Silence warning: Return value of low-level calls not used.
        (success, data) = (success, data);
    }

    function test_transferNativeToken_toContract() public {
        vm.prank(address(tokenOwner));
        (bool success, bytes memory data) = address(this).call{ value: 1 ether }("");

        // Silence warning: Return value of low-level calls not used.
        (success, data) = (success, data);
    }

    function test_transferNativeToken_toEOA_gasOverride() public {
        vm.prank(address(tokenOwner));
        console.log(gasleft());
        (bool success, bytes memory data) = address(0x123).call{ value: 1 ether, gas: 100_000 }("");

        // Silence warning: Return value of low-level calls not used.
        (success, data) = (success, data);

        console.log(gasleft());
    }

    function test_transferNativeToken_toContract_gasOverride() public {
        vm.prank(address(tokenOwner));
        console.log(gasleft());
        (bool success, bytes memory data) = address(this).call{ value: 1 ether, gas: 100_000 }("");
        console.log(gasleft());

        // Silence warning: Return value of low-level calls not used.
        (success, data) = (success, data);
    }
}
