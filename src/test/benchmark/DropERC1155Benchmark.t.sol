// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155, IPermissions, ILazyMint } from "contracts/prebuilts/drop/DropERC1155.sol";

// Test imports
import "../utils/BaseTest.sol";

contract DropERC1155BenchmarkTest is BaseTest {
    using Strings for uint256;
    using Strings for address;

    event TokensLazyMinted(uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes encryptedBaseURI);
    event TokenURIRevealed(uint256 indexed index, string revealedURI);

    DropERC1155 public drop;

    bytes private emptyEncodedBytes = abi.encode("", "");

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        drop = DropERC1155(getContract("DropERC1155"));

        erc20.mint(deployer, 1_000 ether);
        vm.deal(deployer, 1_000 ether);
    }

    /*///////////////////////////////////////////////////////////////
                        DropERC1155 benchmark
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_dropERC1155_claim() public {
        vm.pauseGasMetering();
        uint256 _tokenId = 0;
        string[] memory inputs = new string[](5);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = "300";
        inputs[3] = "5";
        inputs[4] = Strings.toHexString(uint160(address(erc20))); // address of erc20

        bytes memory result = vm.ffi(inputs);
        // revert();
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        DropERC1155.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 5;
        alp.currency = address(erc20);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        drop.lazyMint(500, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(_tokenId, conditions, false);

        erc20.mint(receiver, 10000);
        vm.prank(receiver);
        erc20.approve(address(drop), 10000);

        vm.prank(receiver, receiver);
        vm.resumeGasMetering();
        drop.claim(receiver, _tokenId, 100, address(erc20), 5, alp, "");
    }

    function test_benchmark_dropERC1155_setClaimConditions_five_conditions() public {
        vm.pauseGasMetering();
        uint256 _tokenId = 0;
        string[] memory inputs = new string[](5);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = "300";
        inputs[3] = "5";
        inputs[4] = Strings.toHexString(uint160(address(erc20))); // address of erc20

        bytes memory result = vm.ffi(inputs);
        // revert();
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        DropERC1155.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 5;
        alp.currency = address(erc20);

        vm.warp(1);

        DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](5);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        conditions[1].maxClaimableSupply = 600;
        conditions[1].pricePerToken = 20;
        conditions[1].startTimestamp = 100000;

        conditions[2].maxClaimableSupply = 700;
        conditions[2].pricePerToken = 30;
        conditions[2].startTimestamp = 200000;

        conditions[3].maxClaimableSupply = 800;
        conditions[3].pricePerToken = 40;
        conditions[3].startTimestamp = 300000;

        conditions[4].maxClaimableSupply = 700;
        conditions[4].pricePerToken = 30;
        conditions[4].startTimestamp = 400000;

        vm.prank(deployer);
        drop.lazyMint(500, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        vm.resumeGasMetering();
        drop.setClaimConditions(_tokenId, conditions, false);
    }

    function test_benchmark_dropERC1155_lazyMint() public {
        vm.pauseGasMetering();
        vm.prank(deployer);
        vm.resumeGasMetering();
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);
    }

    // function test_benchmark_dropERC1155_setClaimConditions_one_condition() public {
    //     vm.pauseGasMetering();
    //     uint256 _tokenId = 0;
    //     string[] memory inputs = new string[](5);

    //     inputs[0] = "node";
    //     inputs[1] = "src/test/scripts/generateRoot.ts";
    //     inputs[2] = "300";
    //     inputs[3] = "5";
    //     inputs[4] = Strings.toHexString(uint160(address(erc20))); // address of erc20

    //     bytes memory result = vm.ffi(inputs);
    //     // revert();
    //     bytes32 root = abi.decode(result, (bytes32));

    //     inputs[1] = "src/test/scripts/getProof.ts";
    //     result = vm.ffi(inputs);
    //     bytes32[] memory proofs = abi.decode(result, (bytes32[]));

    //     DropERC1155.AllowlistProof memory alp;
    //     alp.proof = proofs;
    //     alp.quantityLimitPerWallet = 300;
    //     alp.pricePerToken = 5;
    //     alp.currency = address(erc20);

    //     vm.warp(1);

    //     address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

    //     DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](1);
    //     conditions[0].maxClaimableSupply = 500;
    //     conditions[0].quantityLimitPerWallet = 10;
    //     conditions[0].merkleRoot = root;
    //     conditions[0].pricePerToken = 10;
    //     conditions[0].currency = address(erc20);

    //     vm.prank(deployer);
    //     drop.lazyMint(500, "ipfs://", emptyEncodedBytes);
    //     vm.prank(deployer);
    //     vm.resumeGasMetering();
    //     drop.setClaimConditions(_tokenId, conditions, false);
    // }

    // function test_benchmark_dropERC1155_setClaimConditions_two_conditions() public {
    //     vm.pauseGasMetering();
    //     uint256 _tokenId = 0;
    //     string[] memory inputs = new string[](5);

    //     inputs[0] = "node";
    //     inputs[1] = "src/test/scripts/generateRoot.ts";
    //     inputs[2] = "300";
    //     inputs[3] = "5";
    //     inputs[4] = Strings.toHexString(uint160(address(erc20))); // address of erc20

    //     bytes memory result = vm.ffi(inputs);
    //     // revert();
    //     bytes32 root = abi.decode(result, (bytes32));

    //     inputs[1] = "src/test/scripts/getProof.ts";
    //     result = vm.ffi(inputs);
    //     bytes32[] memory proofs = abi.decode(result, (bytes32[]));

    //     DropERC1155.AllowlistProof memory alp;
    //     alp.proof = proofs;
    //     alp.quantityLimitPerWallet = 300;
    //     alp.pricePerToken = 5;
    //     alp.currency = address(erc20);

    //     vm.warp(1);

    //     address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

    //     DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](2);
    //     conditions[0].maxClaimableSupply = 500;
    //     conditions[0].quantityLimitPerWallet = 10;
    //     conditions[0].merkleRoot = root;
    //     conditions[0].pricePerToken = 10;
    //     conditions[0].currency = address(erc20);

    //     conditions[1].maxClaimableSupply = 600;
    //     conditions[1].pricePerToken = 20;
    //     conditions[1].startTimestamp = 100000;

    //     vm.prank(deployer);
    //     drop.lazyMint(500, "ipfs://", emptyEncodedBytes);
    //     vm.prank(deployer);
    //     vm.resumeGasMetering();
    //     drop.setClaimConditions(_tokenId, conditions, false);
    // }

    // function test_benchmark_dropERC1155_setClaimConditions_three_conditions() public {
    //     vm.pauseGasMetering();
    //     uint256 _tokenId = 0;
    //     string[] memory inputs = new string[](5);

    //     inputs[0] = "node";
    //     inputs[1] = "src/test/scripts/generateRoot.ts";
    //     inputs[2] = "300";
    //     inputs[3] = "5";
    //     inputs[4] = Strings.toHexString(uint160(address(erc20))); // address of erc20

    //     bytes memory result = vm.ffi(inputs);
    //     // revert();
    //     bytes32 root = abi.decode(result, (bytes32));

    //     inputs[1] = "src/test/scripts/getProof.ts";
    //     result = vm.ffi(inputs);
    //     bytes32[] memory proofs = abi.decode(result, (bytes32[]));

    //     DropERC1155.AllowlistProof memory alp;
    //     alp.proof = proofs;
    //     alp.quantityLimitPerWallet = 300;
    //     alp.pricePerToken = 5;
    //     alp.currency = address(erc20);

    //     vm.warp(1);

    //     address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

    //     DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](3);
    //     conditions[0].maxClaimableSupply = 500;
    //     conditions[0].quantityLimitPerWallet = 10;
    //     conditions[0].merkleRoot = root;
    //     conditions[0].pricePerToken = 10;
    //     conditions[0].currency = address(erc20);

    //     conditions[1].maxClaimableSupply = 600;
    //     conditions[1].pricePerToken = 20;
    //     conditions[1].startTimestamp = 100000;

    //     conditions[2].maxClaimableSupply = 700;
    //     conditions[2].pricePerToken = 30;
    //     conditions[2].startTimestamp = 200000;

    //     vm.prank(deployer);
    //     drop.lazyMint(500, "ipfs://", emptyEncodedBytes);
    //     vm.prank(deployer);
    //     vm.resumeGasMetering();
    //     drop.setClaimConditions(_tokenId, conditions, false);
    // }
}
