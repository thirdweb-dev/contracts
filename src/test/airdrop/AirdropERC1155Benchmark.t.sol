// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/airdrop/AirdropERC1155.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC1155BenchmarkTest is BaseTest {
    AirdropERC1155 internal drop;

    Wallet internal tokenOwner;

    address[] internal _recipients;
    uint256[] internal _amounts;
    uint256[] internal _tokenIds;

    uint256[] internal _amounts_one;
    address[] internal _recipients_one;
    uint256[] internal _tokenIds_one;

    uint256[] internal _amounts_two;
    address[] internal _recipients_two;
    uint256[] internal _tokenIds_two;

    uint256[] internal _amounts_five;
    address[] internal _recipients_five;
    uint256[] internal _tokenIds_five;

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

        for (uint256 i = 0; i < 1000; i++) {
            if (i < 1) {
                _amounts_one.push(i);
                _tokenIds_one.push(i % 5);
                _recipients_one.push(getActor(uint160(i)));
            }

            if (i < 2) {
                _amounts_two.push(i);
                _tokenIds_two.push(i % 5);
                _recipients_two.push(getActor(uint160(i)));
            }

            if (i < 5) {
                _amounts_five.push(i);
                _tokenIds_five.push(i % 5);
                _recipients_five.push(getActor(uint160(i)));
            }

            _recipients.push(getActor(uint160(i)));
            _tokenIds.push(i % 5);
            _amounts.push(5);
        }

        vm.startPrank(deployer);
    }

    function test_benchmark_airdrop_one() public {
        drop.airdrop(address(erc1155), address(tokenOwner), _recipients_one, _amounts_one, _tokenIds_one);
    }

    function test_benchmark_airdrop_two() public {
        drop.airdrop(address(erc1155), address(tokenOwner), _recipients_two, _amounts_two, _tokenIds_two);
    }

    function test_benchmark_airdrop_five() public {
        drop.airdrop(address(erc1155), address(tokenOwner), _recipients_five, _amounts_five, _tokenIds_five);
    }
}
