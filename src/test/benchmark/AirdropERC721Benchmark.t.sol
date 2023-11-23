// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { AirdropERC721, IAirdropERC721 } from "contracts/prebuilts/unaudited/airdrop/AirdropERC721.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC721BenchmarkTest is BaseTest {
    AirdropERC721 internal drop;

    Wallet internal tokenOwner;

    IAirdropERC721.AirdropContent[] internal _contentsOne;
    IAirdropERC721.AirdropContent[] internal _contentsTwo;

    uint256 countOne;
    uint256 countTwo;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC721(getContract("AirdropERC721"));

        tokenOwner = getWallet();

        erc721.mint(address(tokenOwner), 1500);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(drop), true);

        countOne = 1000;
        countTwo = 200;

        for (uint256 i = 0; i < countOne; i++) {
            _contentsOne.push(IAirdropERC721.AirdropContent({ recipient: getActor(uint160(i)), tokenId: i }));
        }

        for (uint256 i = countOne; i < countOne + countTwo; i++) {
            _contentsTwo.push(IAirdropERC721.AirdropContent({ recipient: getActor(uint160(i)), tokenId: i }));
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Benchmark: AirdropERC721
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_airdropERC721_airdrop() public {
        vm.pauseGasMetering();
        vm.prank(deployer);
        vm.resumeGasMetering();
        drop.airdropERC721(address(erc721), address(tokenOwner), _contentsOne);
    }
}
