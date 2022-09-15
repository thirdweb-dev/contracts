// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/airdrop/AirdropERC721.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC721BenchmarkTest is BaseTest {
    AirdropERC721 internal drop;

    Wallet internal tokenOwner;

    uint256[] internal _tokenIds;
    address[] internal _recipients;

    uint256[] internal _amounts_one;
    address[] internal _recipients_one;

    uint256[] internal _amounts_two;
    address[] internal _recipients_two;

    uint256[] internal _amounts_five;
    address[] internal _recipients_five;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC721(getContract("AirdropERC721"));

        tokenOwner = getWallet();

        erc721.mint(address(tokenOwner), 1000);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(drop), true);

        for (uint256 i = 0; i < 1000; i++) {
            if (i < 1) {
                _amounts_one.push(i);
                _recipients_one.push(getActor(uint160(i)));
            }

            if (i < 2) {
                _amounts_two.push(i);
                _recipients_two.push(getActor(uint160(i)));
            }

            if (i < 5) {
                _amounts_five.push(i);
                _recipients_five.push(getActor(uint160(i)));
            }

            _tokenIds.push(i);
            _recipients.push(getActor(uint160(i)));
        }

        vm.startPrank(deployer);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `createPack`
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_airdrop_one_ERC721() public {
        drop.airdrop(address(erc721), address(tokenOwner), _recipients_one, _amounts_one);
    }

    function test_benchmark_airdrop_two_ERC721() public {
        drop.airdrop(address(erc721), address(tokenOwner), _recipients_two, _amounts_two);
    }

    function test_benchmark_airdrop_five_ERC721() public {
        drop.airdrop(address(erc721), address(tokenOwner), _recipients_five, _amounts_five);
    }
}
