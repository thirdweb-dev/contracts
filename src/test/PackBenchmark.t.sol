// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { Pack } from "contracts/pack/Pack.sol";
import { IPack } from "contracts/interfaces/IPack.sol";
import { ITokenBundle } from "contracts/extension/interface/ITokenBundle.sol";

// Test imports
import { MockERC20 } from "./mocks/MockERC20.sol";
import { Wallet } from "./utils/Wallet.sol";
import "./utils/BaseTest.sol";

contract CreatePackBenchmarkTest is BaseTest {
    Pack internal pack;

    Wallet internal tokenOwner;
    string internal packUri;
    ITokenBundle.Token[] internal packContents;
    uint256[] internal numOfRewardUnits;

    function setUp() public override {
        super.setUp();

        pack = Pack(payable(getContract("Pack")));

        tokenOwner = getWallet();
        packUri = "ipfs://";

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 0,
                totalAmount: 1
            })
        );
        numOfRewardUnits.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc1155),
                tokenType: ITokenBundle.TokenType.ERC1155,
                tokenId: 0,
                totalAmount: 100
            })
        );
        numOfRewardUnits.push(20);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc20),
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 1000 ether
            })
        );
        numOfRewardUnits.push(50);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 1,
                totalAmount: 1
            })
        );
        numOfRewardUnits.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc20),
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 1000 ether
            })
        );
        numOfRewardUnits.push(100);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 2,
                totalAmount: 1
            })
        );
        numOfRewardUnits.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 3,
                totalAmount: 1
            })
        );
        numOfRewardUnits.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 4,
                totalAmount: 1
            })
        );
        numOfRewardUnits.push(1);

        erc20.mint(address(tokenOwner), 2000 ether);
        erc721.mint(address(tokenOwner), 5);
        erc1155.mint(address(tokenOwner), 0, 100);

        tokenOwner.setAllowanceERC20(address(erc20), address(pack), type(uint256).max);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(pack), true);
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(pack), true);

        vm.prank(deployer);
        pack.grantRole(keccak256("MINTER_ROLE"), address(tokenOwner));

        vm.startPrank(address(tokenOwner));
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `createPack`
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing state changes; token owner calls `createPack` to pack owned tokens.
     */
    function test_benchmark_createPack() public {
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, address(0x123));
    }
}

contract OpenPackBenchmarkTest is BaseTest {
    Pack internal pack;

    Wallet internal tokenOwner;
    string internal packUri;
    ITokenBundle.Token[] internal packContents;
    uint256[] internal numOfRewardUnits;

    function setUp() public override {
        super.setUp();

        pack = Pack(payable(getContract("Pack")));

        tokenOwner = getWallet();
        packUri = "ipfs://";

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 0,
                totalAmount: 1
            })
        );
        numOfRewardUnits.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc1155),
                tokenType: ITokenBundle.TokenType.ERC1155,
                tokenId: 0,
                totalAmount: 100
            })
        );
        numOfRewardUnits.push(20);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc20),
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 1000 ether
            })
        );
        numOfRewardUnits.push(50);

        // packContents.push(
        //     ITokenBundle.Token({
        //         assetContract: address(erc721),
        //         tokenType: ITokenBundle.TokenType.ERC721,
        //         tokenId: 1,
        //         totalAmount: 1
        //     })
        // );
        // amountsPerUnit.push(1);

        // packContents.push(
        //     ITokenBundle.Token({
        //         assetContract: address(erc20),
        //         tokenType: ITokenBundle.TokenType.ERC20,
        //         tokenId: 0,
        //         totalAmount: 1000 ether
        //     })
        // );
        // amountsPerUnit.push(10 ether);

        // packContents.push(
        //     ITokenBundle.Token({
        //         assetContract: address(erc721),
        //         tokenType: ITokenBundle.TokenType.ERC721,
        //         tokenId: 2,
        //         totalAmount: 1
        //     })
        // );
        // amountsPerUnit.push(1);

        // packContents.push(
        //     ITokenBundle.Token({
        //         assetContract: address(erc721),
        //         tokenType: ITokenBundle.TokenType.ERC721,
        //         tokenId: 3,
        //         totalAmount: 1
        //     })
        // );
        // amountsPerUnit.push(1);

        // packContents.push(
        //     ITokenBundle.Token({
        //         assetContract: address(erc721),
        //         tokenType: ITokenBundle.TokenType.ERC721,
        //         tokenId: 4,
        //         totalAmount: 1
        //     })
        // );
        // amountsPerUnit.push(1);

        erc20.mint(address(tokenOwner), 2000 ether);
        erc721.mint(address(tokenOwner), 5);
        erc1155.mint(address(tokenOwner), 0, 100);

        tokenOwner.setAllowanceERC20(address(erc20), address(pack), type(uint256).max);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(pack), true);
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(pack), true);

        vm.prank(deployer);
        pack.grantRole(keccak256("MINTER_ROLE"), address(tokenOwner));

        vm.prank(address(tokenOwner));
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, address(0x123));

        vm.startPrank(address(0x123), address(0x123));
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `openPack`
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing state changes; pack owner calls `openPack` to redeem underlying rewards.
     */
    function test_benchmark_openPack() public {
        pack.openPack(0, 1);
    }
}

contract OpenPackLargeInputsTest is BaseTest {
    Pack internal pack;

    Wallet internal tokenOwner;
    address recipient = address(0x123);
    string internal packUri;

    uint256 packId;
    uint256 totalRewardUnits;
    uint256 totalSupply;

    uint256 x;
    uint128 y;
    uint256 z;

    uint256 internal constant MAX_TOKENS = 2000;

    function setUp() public override {
        super.setUp();

        pack = Pack(payable(getContract("Pack")));

        tokenOwner = getWallet();
        packUri = "ipfs://";

        tokenOwner.setAllowanceERC20(address(erc20), address(pack), type(uint256).max);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(pack), true);
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(pack), true);

        vm.prank(deployer);
        pack.grantRole(keccak256("MINTER_ROLE"), address(tokenOwner));

        // pass (1478, 4, 1890).. (gas: 8937393460521767975), total supply: 177189, total reward units: 708756
        // pass (472, 1, 543).. (gas: 8937393460518373840), total supply: 236220, total reward units: 236220
        // pass (96, 112, 447).. (gas: 8937393460517062690), total supply: 467, total reward units: 52304
        // (506, 6, 12950).. (gas: 8937393460518476945), total supply: 41699, total reward units: 250194
        // pass (164, 20, 922).. (gas: 8937393460517318850), total supply: 4335, total reward units: 86700
        // pass (138, 2, 948).. (gas: 8937393460517220399), total supply: 37959, total reward units: 75918
        // pass (32, 11, 978).. (gas: 8937393460516848598), total supply: 1456, total reward units: 16016

        // pass x: 446, y: 22, z: 890 (gas: 8937393460518282035), total supply: 10203, total reward units: 224466
        // pass x: 335, y: 3, z: 1570 (gas: 8937393460517864076), total supply: 54915, total reward units: 164745
        // pass x: 1962, y: 282, z: 219 (gas: 8937393460523355524), total supply: 3239, total reward units: 913398

        // x: 570, y: 497, z: 435 (gas: 8937393460523355524), total supply: 548, total reward units: 272356
        //                          reverts at rewardUnits = new Token[](numOfRewardUnitsToDistribute);
        // x: 412, y: 7, z: 11830 (gas: 8937393460523355524), total supply: 29834, total reward units: 208838
        //                          reverts while transferring reward units to receipient
        // x: 1322, y: 211, z: 1994 (gas: 8937393460523355524), total supply: 3104, total reward units: 6544944
        //                          reverts at rewardUnits = new Token[](numOfRewardUnitsToDistribute);
        // x: 1578, y: 1294, z: 515 (gas: 8937393460523355524), total supply: 580, total reward units: 750520
        //                          reverts at rewardUnits = new Token[](numOfRewardUnitsToDistribute);
        // x: 404, y: 38, z: 3950 (gas: 8937393460523355524), total supply: 5201, total reward units: 197638
        //                          reverts at rewardUnits = new Token[](numOfRewardUnitsToDistribute);
        x = 404;
        y = 38;
        z = 1700;

        (ITokenBundle.Token[] memory tokensToPack, uint256[] memory rewardUnits) = getTokensToPack(x);
        if (tokensToPack.length == 0) {
            return;
        }

        packId = pack.nextTokenIdToMint();
        uint256 nativeTokenPacked;

        for (uint256 i = 0; i < tokensToPack.length; i += 1) {
            totalRewardUnits += rewardUnits[i];
            if (tokensToPack[i].assetContract == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
                nativeTokenPacked += tokensToPack[i].totalAmount;
            }
        }
        vm.assume(y > 0 && totalRewardUnits % y == 0);
        vm.deal(address(tokenOwner), nativeTokenPacked);

        vm.prank(address(tokenOwner));
        (, totalSupply) = pack.createPack{ value: nativeTokenPacked }(
            tokensToPack,
            rewardUnits,
            packUri,
            0,
            y,
            recipient
        );

        vm.assume(z <= totalSupply);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `openPack`
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing state changes; pack owner calls `openPack` to redeem underlying rewards.
     */
    function test_fuzz_failing_state_openPack() public {
        console.log(gasleft());
        console2.log("total supply: ", totalSupply);
        console2.log("total reward units: ", totalRewardUnits);

        vm.prank(recipient, recipient);
        ITokenBundle.Token[] memory rewardsReceived = pack.openPack(packId, z);
        console2.log("received reward units: ", rewardsReceived.length);

        assertEq(packUri, pack.uri(packId));

        (
            uint256 nativeTokenAmount,
            uint256 erc20Amount,
            uint256[] memory erc1155Amounts,
            uint256 erc721Amount
        ) = checkBalances(rewardsReceived);

        assertEq(address(recipient).balance, nativeTokenAmount);
        assertEq(erc20.balanceOf(address(recipient)), erc20Amount);
        assertEq(erc721.balanceOf(address(recipient)), erc721Amount);

        for (uint256 i = 0; i < erc1155Amounts.length; i += 1) {
            assertEq(erc1155.balanceOf(address(recipient), i), erc1155Amounts[i]);
        }
    }

    function getTokensToPack(uint256 len)
        internal
        returns (ITokenBundle.Token[] memory tokensToPack, uint256[] memory rewardUnits)
    {
        vm.assume(len < MAX_TOKENS);
        tokensToPack = new ITokenBundle.Token[](len);
        rewardUnits = new uint256[](len);

        for (uint256 i = 0; i < len; i += 1) {
            uint256 random = uint256(keccak256(abi.encodePacked(len + i))) % MAX_TOKENS;
            uint256 selector = random % 4;

            if (selector == 0) {
                tokensToPack[i] = ITokenBundle.Token({
                    assetContract: address(erc20),
                    tokenType: ITokenBundle.TokenType.ERC20,
                    tokenId: 0,
                    totalAmount: (random + 1) * 10 ether
                });
                rewardUnits[i] = random + 1;

                erc20.mint(address(tokenOwner), tokensToPack[i].totalAmount);
            } else if (selector == 1) {
                uint256 tokenId = erc721.nextTokenIdToMint();

                tokensToPack[i] = ITokenBundle.Token({
                    assetContract: address(erc721),
                    tokenType: ITokenBundle.TokenType.ERC721,
                    tokenId: tokenId,
                    totalAmount: 1
                });
                rewardUnits[i] = 1;

                erc721.mint(address(tokenOwner), 1);
            } else if (selector == 2) {
                tokensToPack[i] = ITokenBundle.Token({
                    assetContract: address(erc1155),
                    tokenType: ITokenBundle.TokenType.ERC1155,
                    tokenId: random,
                    totalAmount: (random + 1) * 10
                });
                rewardUnits[i] = random + 1;

                erc1155.mint(address(tokenOwner), tokensToPack[i].tokenId, tokensToPack[i].totalAmount);
            } else if (selector == 3) {
                tokensToPack[i] = ITokenBundle.Token({
                    assetContract: address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
                    tokenType: ITokenBundle.TokenType.ERC20,
                    tokenId: 0,
                    totalAmount: 5 ether
                });
                rewardUnits[i] = 5;
            }
        }
    }

    function checkBalances(ITokenBundle.Token[] memory rewardUnits)
        internal
        pure
        returns (
            uint256 nativeTokenAmount,
            uint256 erc20Amount,
            uint256[] memory erc1155Amounts,
            uint256 erc721Amount
        )
    {
        erc1155Amounts = new uint256[](MAX_TOKENS);

        for (uint256 i = 0; i < rewardUnits.length; i++) {
            // console2.log("----- reward unit number: ", i, "------");
            // console2.log("asset contract: ", rewardUnits[i].assetContract);
            // console2.log("token type: ", uint256(rewardUnits[i].tokenType));
            // console2.log("tokenId: ", rewardUnits[i].tokenId);
            if (rewardUnits[i].tokenType == ITokenBundle.TokenType.ERC20) {
                if (rewardUnits[i].assetContract == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
                    // console2.log("total amount: ", rewardUnits[i].totalAmount / 1 ether, "ether");
                    // console.log("balance of recipient: ", address(recipient).balance);
                    nativeTokenAmount += rewardUnits[i].totalAmount;
                } else {
                    // console2.log("total amount: ", rewardUnits[i].totalAmount / 1 ether, "ether");
                    // console.log("balance of recipient: ", erc20.balanceOf(address(recipient)) / 1 ether, "ether");
                    erc20Amount += rewardUnits[i].totalAmount;
                }
            } else if (rewardUnits[i].tokenType == ITokenBundle.TokenType.ERC1155) {
                // console2.log("total amount: ", rewardUnits[i].totalAmount);
                // console.log("balance of recipient: ", erc1155.balanceOf(address(recipient), rewardUnits[i].tokenId));
                erc1155Amounts[rewardUnits[i].tokenId] += rewardUnits[i].totalAmount;
            } else if (rewardUnits[i].tokenType == ITokenBundle.TokenType.ERC721) {
                // console2.log("total amount: ", rewardUnits[i].totalAmount);
                // console.log("balance of recipient: ", erc721.balanceOf(address(recipient)));
                erc721Amount += rewardUnits[i].totalAmount;
            }
            // console2.log("");
        }
    }
}
