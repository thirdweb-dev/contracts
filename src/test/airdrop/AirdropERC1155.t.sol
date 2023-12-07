// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { AirdropERC1155, IAirdropERC1155 } from "contracts/prebuilts/unaudited/airdrop/AirdropERC1155.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC1155Test is BaseTest {
    AirdropERC1155 internal drop;

    Wallet internal tokenOwner;

    IAirdropERC1155.AirdropContent[] internal _contentsOne;
    IAirdropERC1155.AirdropContent[] internal _contentsTwo;

    uint256 countOne;
    uint256 countTwo;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC1155(getContract("AirdropERC1155"));

        tokenOwner = getWallet();

        erc1155.mint(address(tokenOwner), 0, 1000);
        erc1155.mint(address(tokenOwner), 1, 2000);
        erc1155.mint(address(tokenOwner), 2, 3000);
        erc1155.mint(address(tokenOwner), 3, 4000);
        erc1155.mint(address(tokenOwner), 4, 5000);

        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(drop), true);

        countOne = 1000;
        countTwo = 200;

        for (uint256 i = 0; i < countOne; i++) {
            _contentsOne.push(
                IAirdropERC1155.AirdropContent({ recipient: getActor(uint160(i)), tokenId: i % 5, amount: 5 })
            );
        }

        for (uint256 i = countOne; i < countOne + countTwo; i++) {
            _contentsTwo.push(
                IAirdropERC1155.AirdropContent({ recipient: getActor(uint160(i)), tokenId: i % 5, amount: 5 })
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: stateless airdrop
    //////////////////////////////////////////////////////////////*/

    function test_state_airdrop() public {
        vm.prank(deployer);
        drop.airdropERC1155(address(erc1155), address(tokenOwner), _contentsOne);

        for (uint256 i = 0; i < countOne; i++) {
            assertEq(erc1155.balanceOf(_contentsOne[i].recipient, i % 5), 5);
        }

        assertEq(erc1155.balanceOf(address(tokenOwner), 0), 0);
        assertEq(erc1155.balanceOf(address(tokenOwner), 1), 1000);
        assertEq(erc1155.balanceOf(address(tokenOwner), 2), 2000);
        assertEq(erc1155.balanceOf(address(tokenOwner), 3), 3000);
        assertEq(erc1155.balanceOf(address(tokenOwner), 4), 4000);
    }

    function test_revert_airdrop_notOwner() public {
        vm.prank(address(25));
        vm.expectRevert("Not authorized.");
        drop.airdropERC1155(address(erc1155), address(tokenOwner), _contentsOne);
    }

    function test_revert_airdrop_notApproved() public {
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(drop), false);

        vm.startPrank(deployer);
        vm.expectRevert("Not balance or approved");
        drop.airdropERC1155(address(erc1155), address(tokenOwner), _contentsOne);
        vm.stopPrank();
    }
}

contract AirdropERC1155GasTest is BaseTest {
    AirdropERC1155 internal drop;

    Wallet internal tokenOwner;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC1155(getContract("AirdropERC1155"));

        tokenOwner = getWallet();

        erc1155.mint(address(tokenOwner), 0, 1000);

        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(drop), true);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: gas benchmarks, etc.
    //////////////////////////////////////////////////////////////*/

    function test_safeTransferFrom_toEOA() public {
        vm.prank(address(tokenOwner));
        erc1155.safeTransferFrom(address(tokenOwner), address(0x123), 0, 10, "");
    }

    function test_safeTransferFrom_toContract() public {
        vm.prank(address(tokenOwner));
        erc1155.safeTransferFrom(address(tokenOwner), address(this), 0, 10, "");
    }

    function test_safeTransferFrom_toEOA_gasOverride() public {
        vm.prank(address(tokenOwner));
        console.log(gasleft());
        erc1155.safeTransferFrom{ gas: 100_000 }(address(tokenOwner), address(this), 0, 10, "");
        console.log(gasleft());
    }

    function test_safeTransferFrom_toContract_gasOverride() public {
        vm.prank(address(tokenOwner));
        console.log(gasleft());
        erc1155.safeTransferFrom{ gas: 100_000 }(address(tokenOwner), address(this), 0, 10, "");
        console.log(gasleft());
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}
