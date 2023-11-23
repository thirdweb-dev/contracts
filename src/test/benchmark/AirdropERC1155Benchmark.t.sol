// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { AirdropERC1155, IAirdropERC1155 } from "contracts/prebuilts/unaudited/airdrop/AirdropERC1155.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC1155BenchmarkTest is BaseTest {
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
                        Benchmark: AirdropERC1155
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_airdropERC1155_airdrop() public {
        vm.pauseGasMetering();
        vm.prank(deployer);
        vm.resumeGasMetering();
        drop.airdropERC1155(address(erc1155), address(tokenOwner), _contentsOne);
    }
}
