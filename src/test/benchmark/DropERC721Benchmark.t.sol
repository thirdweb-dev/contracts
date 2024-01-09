// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721, IDelayedReveal, ERC721AUpgradeable, IPermissions, ILazyMint } from "contracts/prebuilts/drop/DropERC721.sol";

// Test imports
import { IERC721AUpgradeable } from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import "../utils/BaseTest.sol";

contract DropERC721BenchmarkTest is BaseTest {
    using Strings for uint256;
    using Strings for address;

    DropERC721 public drop;

    bytes private emptyEncodedBytes = abi.encode("", "");

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        drop = DropERC721(getContract("DropERC721"));

        erc20.mint(deployer, 1_000 ether);
        vm.deal(deployer, 1_000 ether);
    }

    /*///////////////////////////////////////////////////////////////
                        DropERC721 benchmark
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_dropERC721_claim_five_tokens() public {
        vm.pauseGasMetering();
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

        DropERC721.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 5;
        alp.currency = address(erc20);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        drop.lazyMint(500, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        vm.prank(receiver, receiver);

        erc20.mint(receiver, 10000);
        vm.prank(receiver);
        erc20.approve(address(drop), 10000);

        vm.prank(receiver, receiver);
        vm.resumeGasMetering();
        drop.claim(receiver, 5, address(erc20), 5, alp, "");
    }

    function test_benchmark_dropERC721_setClaimConditions_five_conditions() public {
        vm.pauseGasMetering();
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

        DropERC721.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 5;
        alp.currency = address(erc20);

        vm.warp(1);

        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](5);
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
        vm.resumeGasMetering();
        drop.setClaimConditions(conditions, false);
    }

    function test_benchmark_dropERC721_lazyMint() public {
        vm.pauseGasMetering();
        vm.prank(deployer);
        vm.resumeGasMetering();
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);
    }

    function test_benchmark_dropERC721_lazyMint_for_delayed_reveal() public {
        vm.pauseGasMetering();
        uint256 amountToLazyMint = 100;
        string memory baseURI = "ipfs://";
        bytes memory encryptedBaseURI = "encryptedBaseURI://";
        bytes32 provenanceHash = bytes32("whatever");

        vm.prank(deployer);
        vm.resumeGasMetering();
        drop.lazyMint(amountToLazyMint, baseURI, abi.encode(encryptedBaseURI, provenanceHash));
    }

    function test_benchmark_dropERC721_reveal() public {
        vm.pauseGasMetering();

        bytes memory key = "key";
        uint256 amountToLazyMint = 100;
        bytes memory secretURI = "ipfs://";
        string memory placeholderURI = "abcd://";
        bytes memory encryptedURI = drop.encryptDecrypt(secretURI, key);
        bytes32 provenanceHash = keccak256(abi.encodePacked(secretURI, key, block.chainid));

        vm.prank(deployer);
        drop.lazyMint(amountToLazyMint, placeholderURI, abi.encode(encryptedURI, provenanceHash));

        vm.prank(deployer);
        vm.resumeGasMetering();
        drop.reveal(0, key);
    }

    // function test_benchmark_dropERC721_claim_one_token() public {
    //     vm.pauseGasMetering();
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

    //     DropERC721.AllowlistProof memory alp;
    //     alp.proof = proofs;
    //     alp.quantityLimitPerWallet = 300;
    //     alp.pricePerToken = 5;
    //     alp.currency = address(erc20);

    //     vm.warp(1);

    //     address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

    //     DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
    //     conditions[0].maxClaimableSupply = 500;
    //     conditions[0].quantityLimitPerWallet = 10;
    //     conditions[0].merkleRoot = root;
    //     conditions[0].pricePerToken = 10;
    //     conditions[0].currency = address(erc20);

    //     vm.prank(deployer);
    //     drop.lazyMint(500, "ipfs://", emptyEncodedBytes);
    //     vm.prank(deployer);
    //     drop.setClaimConditions(conditions, false);

    //     vm.prank(receiver, receiver);

    //     erc20.mint(receiver, 10000);
    //     vm.prank(receiver);
    //     erc20.approve(address(drop), 10000);

    //     vm.prank(receiver, receiver);
    //     vm.resumeGasMetering();
    //     drop.claim(receiver, 1, address(erc20), 5, alp, "");
    // }

    // function test_benchmark_dropERC721_claim_two_tokens() public {
    //     vm.pauseGasMetering();
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

    //     DropERC721.AllowlistProof memory alp;
    //     alp.proof = proofs;
    //     alp.quantityLimitPerWallet = 300;
    //     alp.pricePerToken = 5;
    //     alp.currency = address(erc20);

    //     vm.warp(1);

    //     address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

    //     DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
    //     conditions[0].maxClaimableSupply = 500;
    //     conditions[0].quantityLimitPerWallet = 10;
    //     conditions[0].merkleRoot = root;
    //     conditions[0].pricePerToken = 10;
    //     conditions[0].currency = address(erc20);

    //     vm.prank(deployer);
    //     drop.lazyMint(500, "ipfs://", emptyEncodedBytes);
    //     vm.prank(deployer);
    //     drop.setClaimConditions(conditions, false);

    //     vm.prank(receiver, receiver);

    //     erc20.mint(receiver, 10000);
    //     vm.prank(receiver);
    //     erc20.approve(address(drop), 10000);

    //     vm.prank(receiver, receiver);
    //     vm.resumeGasMetering();
    //     drop.claim(receiver, 2, address(erc20), 5, alp, "");
    // }

    // function test_benchmark_dropERC721_claim_three_tokens() public {
    //     vm.pauseGasMetering();
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

    //     DropERC721.AllowlistProof memory alp;
    //     alp.proof = proofs;
    //     alp.quantityLimitPerWallet = 300;
    //     alp.pricePerToken = 5;
    //     alp.currency = address(erc20);

    //     vm.warp(1);

    //     address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

    //     DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
    //     conditions[0].maxClaimableSupply = 500;
    //     conditions[0].quantityLimitPerWallet = 10;
    //     conditions[0].merkleRoot = root;
    //     conditions[0].pricePerToken = 10;
    //     conditions[0].currency = address(erc20);

    //     vm.prank(deployer);
    //     drop.lazyMint(500, "ipfs://", emptyEncodedBytes);
    //     vm.prank(deployer);
    //     drop.setClaimConditions(conditions, false);

    //     vm.prank(receiver, receiver);

    //     erc20.mint(receiver, 10000);
    //     vm.prank(receiver);
    //     erc20.approve(address(drop), 10000);

    //     vm.prank(receiver, receiver);
    //     vm.resumeGasMetering();
    //     drop.claim(receiver, 3, address(erc20), 5, alp, "");
    // }

    // function test_benchmark_dropERC721_setClaimConditions_one_condition() public {
    //     vm.pauseGasMetering();
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

    //     DropERC721.AllowlistProof memory alp;
    //     alp.proof = proofs;
    //     alp.quantityLimitPerWallet = 300;
    //     alp.pricePerToken = 5;
    //     alp.currency = address(erc20);

    //     vm.warp(1);

    //     address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

    //     DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
    //     conditions[0].maxClaimableSupply = 500;
    //     conditions[0].quantityLimitPerWallet = 10;
    //     conditions[0].merkleRoot = root;
    //     conditions[0].pricePerToken = 10;
    //     conditions[0].currency = address(erc20);

    //     vm.prank(deployer);
    //     vm.resumeGasMetering();
    //     drop.setClaimConditions(conditions, false);
    // }

    // function test_benchmark_dropERC721_setClaimConditions_two_conditions() public {
    //     vm.pauseGasMetering();
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

    //     DropERC721.AllowlistProof memory alp;
    //     alp.proof = proofs;
    //     alp.quantityLimitPerWallet = 300;
    //     alp.pricePerToken = 5;
    //     alp.currency = address(erc20);

    //     vm.warp(1);

    //     address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

    //     DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](2);
    //     conditions[0].maxClaimableSupply = 500;
    //     conditions[0].quantityLimitPerWallet = 10;
    //     conditions[0].merkleRoot = root;
    //     conditions[0].pricePerToken = 10;
    //     conditions[0].currency = address(erc20);

    //     conditions[1].maxClaimableSupply = 600;
    //     conditions[1].pricePerToken = 20;
    //     conditions[1].startTimestamp = 100000;

    //     vm.prank(deployer);
    //     vm.resumeGasMetering();
    //     drop.setClaimConditions(conditions, false);
    // }

    // function test_benchmark_dropERC721_setClaimConditions_three_conditions() public {
    //     vm.pauseGasMetering();
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

    //     DropERC721.AllowlistProof memory alp;
    //     alp.proof = proofs;
    //     alp.quantityLimitPerWallet = 300;
    //     alp.pricePerToken = 5;
    //     alp.currency = address(erc20);

    //     vm.warp(1);

    //     address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

    //     DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](3);
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
    //     vm.resumeGasMetering();
    //     drop.setClaimConditions(conditions, false);
    // }
}
