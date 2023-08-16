// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { PackVRFDirect, IERC2981Upgradeable, IERC721Receiver, IERC1155Upgradeable } from "contracts/prebuilts/pack/PackVRFDirect.sol";
import { IPack } from "contracts/prebuilts/interface/IPack.sol";
import { ITokenBundle } from "contracts/extension/interface/ITokenBundle.sol";

// Test imports
import { MockERC20 } from "../mocks/MockERC20.sol";
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract PackVRFDirectBenchmarkTest is BaseTest {
    /// @notice Emitted when a set of packs is created.
    event PackCreated(uint256 indexed packId, address recipient, uint256 totalPacksCreated);

    /// @notice Emitted when the opening of a pack is requested.
    event PackOpenRequested(address indexed opener, uint256 indexed packId, uint256 amountToOpen, uint256 requestId);

    /// @notice Emitted when Chainlink VRF fulfills a random number request.
    event PackRandomnessFulfilled(uint256 indexed packId, uint256 indexed requestId);

    /// @notice Emitted when a pack is opened.
    event PackOpened(
        uint256 indexed packId,
        address indexed opener,
        uint256 numOfPacksOpened,
        ITokenBundle.Token[] rewardUnitsDistributed
    );

    PackVRFDirect internal pack;

    Wallet internal tokenOwner;
    string internal packUri;
    ITokenBundle.Token[] internal packContents;
    ITokenBundle.Token[] internal additionalContents;
    uint256[] internal numOfRewardUnits;
    uint256[] internal additionalContentsRewardUnits;

    function setUp() public virtual override {
        super.setUp();

        pack = PackVRFDirect(payable(getContract("PackVRFDirect")));

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
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 2,
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

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 5,
                totalAmount: 1
            })
        );
        numOfRewardUnits.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc1155),
                tokenType: ITokenBundle.TokenType.ERC1155,
                tokenId: 1,
                totalAmount: 500
            })
        );
        numOfRewardUnits.push(50);

        erc20.mint(address(tokenOwner), 2000 ether);
        erc721.mint(address(tokenOwner), 6);
        erc1155.mint(address(tokenOwner), 0, 100);
        erc1155.mint(address(tokenOwner), 1, 500);

        // additional contents, to check `addPackContents`
        additionalContents.push(
            ITokenBundle.Token({
                assetContract: address(erc1155),
                tokenType: ITokenBundle.TokenType.ERC1155,
                tokenId: 2,
                totalAmount: 200
            })
        );
        additionalContentsRewardUnits.push(50);

        additionalContents.push(
            ITokenBundle.Token({
                assetContract: address(erc20),
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 1000 ether
            })
        );
        additionalContentsRewardUnits.push(100);

        tokenOwner.setAllowanceERC20(address(erc20), address(pack), type(uint256).max);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(pack), true);
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(pack), true);

        vm.prank(deployer);
        pack.grantRole(keccak256("MINTER_ROLE"), address(tokenOwner));
    }

    /*///////////////////////////////////////////////////////////////
                        Benchmark: PackVRFDirect
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_packvrf_createPack() public {
        vm.pauseGasMetering();
        address recipient = address(1);
        vm.prank(address(tokenOwner));
        vm.resumeGasMetering();
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);
    }

    function test_benchmark_packvrf_openPackAndClaimRewards() public {
        vm.pauseGasMetering();
        vm.warp(1000);
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 2, recipient);

        vm.prank(recipient, recipient);
        vm.resumeGasMetering();
    }

    function test_benchmark_packvrf_openPack() public {
        vm.pauseGasMetering();
        vm.warp(1000);
        uint256 packId = pack.nextTokenIdToMint();
        uint256 packsToOpen = 3;
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 2, recipient);

        vm.prank(recipient, recipient);
        vm.resumeGasMetering();
        pack.openPack(packId, packsToOpen);
    }
}
