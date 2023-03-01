// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

import "contracts/interfaces/airdrop/IAirdropERC20.sol";

contract GriefingContract {
    event YouAreBeingGriefed();

    receive() external payable {
        grief();
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        grief();
        return GriefingContract.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        grief();
        return GriefingContract.onERC1155Received.selector;
    }

    function grief() internal {
        while (true) {
            emit YouAreBeingGriefed();
        }
    }
}

contract AirdropGriefingTest is BaseTest {
    AirdropERC721 internal dropERC721;
    AirdropERC1155 internal dropERC1155;
    AirdropERC20 internal dropERC20;

    Wallet internal tokenOwner;

    IAirdropERC721.AirdropContent[] internal contentsERC721;
    IAirdropERC1155.AirdropContent[] internal contentsERC1155;
    IAirdropERC20.AirdropContent[] internal contentsERC20;

    GriefingContract private griefingContract;

    function setUp() public override {
        super.setUp();

        tokenOwner = getWallet();

        // setup erc721
        dropERC721 = AirdropERC721(getContract("AirdropERC721"));

        erc721.mint(address(tokenOwner), 1500);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(dropERC721), true);

        griefingContract = new GriefingContract();

        // add griefing contract to airdrop
        contentsERC721.push(
            IAirdropERC721.AirdropContent({
                tokenAddress: address(erc721),
                tokenOwner: address(tokenOwner),
                recipient: address(griefingContract),
                tokenId: 50
            })
        );

        for (uint256 i = 0; i < 5; i++) {
            contentsERC721.push(
                IAirdropERC721.AirdropContent({
                    tokenAddress: address(erc721),
                    tokenOwner: address(tokenOwner),
                    recipient: getActor(uint160(i)),
                    tokenId: i
                })
            );
        }

        vm.prank(deployer);
        dropERC721.addRecipients(contentsERC721);

        // setup erc1155
        dropERC1155 = AirdropERC1155(getContract("AirdropERC1155"));

        erc1155.mint(address(tokenOwner), 1, 1500);
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(dropERC1155), true);

        //add griefing contract to airdrop
        contentsERC1155.push(
            IAirdropERC1155.AirdropContent({
                tokenAddress: address(erc1155),
                tokenOwner: address(tokenOwner),
                recipient: address(griefingContract),
                tokenId: 1,
                amount: 1
            })
        );

        for (uint256 i = 0; i < 5; i++) {
            contentsERC1155.push(
                IAirdropERC1155.AirdropContent({
                    tokenAddress: address(erc1155),
                    tokenOwner: address(tokenOwner),
                    recipient: getActor(uint160(i)),
                    tokenId: 1,
                    amount: 1
                })
            );
        }

        vm.prank(deployer);
        dropERC1155.addRecipients(contentsERC1155);

        // setup erc20
        dropERC20 = AirdropERC20(getContract("AirdropERC20"));

        //add griefing contract to airdrop
        contentsERC20.push(
            IAirdropERC20.AirdropContent({
                tokenAddress: address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
                tokenOwner: address(tokenOwner),
                recipient: address(griefingContract),
                amount: 1
            })
        );

        for (uint256 i = 0; i < 5; i++) {
            contentsERC20.push(
                IAirdropERC20.AirdropContent({
                    tokenAddress: address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
                    tokenOwner: address(tokenOwner),
                    recipient: getActor(uint160(i)),
                    amount: 1
                })
            );
        }

        vm.deal(deployer, 10_000 ether);

        vm.prank(deployer);
        dropERC20.addRecipients{ value: 6 }(contentsERC20);
    }

    function test_GriefingERC721_Exceeds_30M_Gas() public {
        vm.prank(deployer);
        dropERC721.processPayments(6);
    }

    function test_GriefingERC1155_Exceeds_30M_Gas() public {
        vm.prank(deployer);
        dropERC1155.processPayments(6);
    }

    function test_GriefingERC20_Exceeds_30M_Gas() public {
        vm.prank(deployer);
        dropERC20.processPayments(6);
    }
}
