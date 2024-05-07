// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC20 } from "contracts/prebuilts/drop/DropERC20.sol";

// Test imports
import "../utils/BaseTest.sol";

contract DropERC20BenchmarkTest is BaseTest {
    using Strings for uint256;
    using Strings for address;

    DropERC20 public drop;

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        drop = DropERC20(getContract("DropERC20"));

        erc20.mint(deployer, 1_000 ether);
        vm.deal(deployer, 1_000 ether);
    }

    /*///////////////////////////////////////////////////////////////
                        DropERC20 benchmark
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_dropERC20_setClaimConditions_five_conditions() public {
        vm.pauseGasMetering();
        string[] memory inputs = new string[](5);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = Strings.toString(uint256(300 ether));
        inputs[3] = Strings.toString(uint256(1 ether));
        inputs[4] = Strings.toHexString(uint160(address(erc20))); // address of erc20

        bytes memory result = vm.ffi(inputs);
        // revert();
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        DropERC20.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300 ether;
        alp.pricePerToken = 1 ether;
        alp.currency = address(erc20);

        vm.warp(1);

        DropERC20.ClaimCondition[] memory conditions = new DropERC20.ClaimCondition[](5);
        conditions[0].maxClaimableSupply = 500 ether;
        conditions[0].quantityLimitPerWallet = 10 ether;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 5 ether;
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

    function test_benchmark_dropERC20_claim() public {
        vm.pauseGasMetering();
        string[] memory inputs = new string[](5);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = Strings.toString(uint256(300 ether));
        inputs[3] = Strings.toString(uint256(1 ether));
        inputs[4] = Strings.toHexString(uint160(address(erc20))); // address of erc20

        bytes memory result = vm.ffi(inputs);
        // revert();
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        DropERC20.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300 ether;
        alp.pricePerToken = 1 ether;
        alp.currency = address(erc20);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        DropERC20.ClaimCondition[] memory conditions = new DropERC20.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500 ether;
        conditions[0].quantityLimitPerWallet = 10 ether;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 5 ether;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        erc20.mint(receiver, 1000 ether);
        vm.prank(receiver);
        erc20.approve(address(drop), 1000 ether);

        vm.prank(receiver, receiver);
        vm.resumeGasMetering();
        drop.claim(receiver, 100 ether, address(erc20), 1 ether, alp, "");
    }

    // function test_benchmark_dropERC20_setClaimConditions_one_condition() public {
    //     vm.pauseGasMetering();
    //     string[] memory inputs = new string[](5);

    //     inputs[0] = "node";
    //     inputs[1] = "src/test/scripts/generateRoot.ts";
    //     inputs[2] = Strings.toString(300 ether);
    //     inputs[3] = Strings.toString(1 ether);
    //     inputs[4] = Strings.toHexString(uint160(address(erc20))); // address of erc20

    //     bytes memory result = vm.ffi(inputs);
    //     // revert();
    //     bytes32 root = abi.decode(result, (bytes32));

    //     inputs[1] = "src/test/scripts/getProof.ts";
    //     result = vm.ffi(inputs);
    //     bytes32[] memory proofs = abi.decode(result, (bytes32[]));

    //     DropERC20.AllowlistProof memory alp;
    //     alp.proof = proofs;
    //     alp.quantityLimitPerWallet = 300 ether;
    //     alp.pricePerToken = 1 ether;
    //     alp.currency = address(erc20);

    //     vm.warp(1);

    //     address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

    //     DropERC20.ClaimCondition[] memory conditions = new DropERC20.ClaimCondition[](1);
    //     conditions[0].maxClaimableSupply = 500 ether;
    //     conditions[0].quantityLimitPerWallet = 10 ether;
    //     conditions[0].merkleRoot = root;
    //     conditions[0].pricePerToken = 5 ether;
    //     conditions[0].currency = address(erc20);

    //     vm.prank(deployer);
    //     vm.resumeGasMetering();
    //     drop.setClaimConditions(conditions, false);
    // }

    // function test_benchmark_dropERC20_setClaimConditions_two_conditions() public {
    //     vm.pauseGasMetering();
    //     string[] memory inputs = new string[](5);

    //     inputs[0] = "node";
    //     inputs[1] = "src/test/scripts/generateRoot.ts";
    //     inputs[2] = Strings.toString(300 ether);
    //     inputs[3] = Strings.toString(1 ether);
    //     inputs[4] = Strings.toHexString(uint160(address(erc20))); // address of erc20

    //     bytes memory result = vm.ffi(inputs);
    //     // revert();
    //     bytes32 root = abi.decode(result, (bytes32));

    //     inputs[1] = "src/test/scripts/getProof.ts";
    //     result = vm.ffi(inputs);
    //     bytes32[] memory proofs = abi.decode(result, (bytes32[]));

    //     DropERC20.AllowlistProof memory alp;
    //     alp.proof = proofs;
    //     alp.quantityLimitPerWallet = 300 ether;
    //     alp.pricePerToken = 1 ether;
    //     alp.currency = address(erc20);

    //     vm.warp(1);

    //     address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

    //     DropERC20.ClaimCondition[] memory conditions = new DropERC20.ClaimCondition[](2);
    //     conditions[0].maxClaimableSupply = 500 ether;
    //     conditions[0].quantityLimitPerWallet = 10 ether;
    //     conditions[0].merkleRoot = root;
    //     conditions[0].pricePerToken = 5 ether;
    //     conditions[0].currency = address(erc20);

    //     conditions[1].maxClaimableSupply = 600;
    //     conditions[1].pricePerToken = 20;
    //     conditions[1].startTimestamp = 100000;

    //     vm.prank(deployer);
    //     vm.resumeGasMetering();
    //     drop.setClaimConditions(conditions, false);
    // }

    // function test_benchmark_dropERC20_setClaimConditions_three_conditions() public {
    //     vm.pauseGasMetering();
    //     string[] memory inputs = new string[](5);

    //     inputs[0] = "node";
    //     inputs[1] = "src/test/scripts/generateRoot.ts";
    //     inputs[2] = Strings.toString(300 ether);
    //     inputs[3] = Strings.toString(1 ether);
    //     inputs[4] = Strings.toHexString(uint160(address(erc20))); // address of erc20

    //     bytes memory result = vm.ffi(inputs);
    //     // revert();
    //     bytes32 root = abi.decode(result, (bytes32));

    //     inputs[1] = "src/test/scripts/getProof.ts";
    //     result = vm.ffi(inputs);
    //     bytes32[] memory proofs = abi.decode(result, (bytes32[]));

    //     DropERC20.AllowlistProof memory alp;
    //     alp.proof = proofs;
    //     alp.quantityLimitPerWallet = 300 ether;
    //     alp.pricePerToken = 1 ether;
    //     alp.currency = address(erc20);

    //     vm.warp(1);

    //     address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

    //     DropERC20.ClaimCondition[] memory conditions = new DropERC20.ClaimCondition[](3);
    //     conditions[0].maxClaimableSupply = 500 ether;
    //     conditions[0].quantityLimitPerWallet = 10 ether;
    //     conditions[0].merkleRoot = root;
    //     conditions[0].pricePerToken = 5 ether;
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
