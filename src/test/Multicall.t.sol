// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@std/Test.sol";

import { Multicall } from "contracts/extension/Multicall.sol";
import { Forwarder } from "contracts/infra/forwarder/Forwarder.sol";
import { ERC2771Context } from "contracts/extension/upgradeable/ERC2771Context.sol";

contract MockMulticallForwarderConsumer is Multicall, ERC2771Context {
    event Increment(address caller);
    mapping(address => uint256) public counter;

    constructor(address[] memory trustedForwarders) ERC2771Context(trustedForwarders) {}

    function increment() external {
        counter[_msgSender()]++;
        emit Increment(_msgSender());
    }

    function _msgSender() internal view override(Multicall, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }
}

contract MulticallTest is Test {
    // Target (mock) contract
    address internal consumer;

    address internal user1;
    uint256 internal user1Pkey = 100;

    address internal user2;
    uint256 internal user2Pkey = 200;

    // Forwarder details
    Forwarder internal forwarder;

    bytes32 internal typehashForwardRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;

    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    function setUp() public {
        user1 = vm.addr(user1Pkey);
        user2 = vm.addr(user2Pkey);

        // Deploy forwarder
        forwarder = new Forwarder();

        // Deploy consumer
        address[] memory forwarders = new address[](1);
        forwarders[0] = address(forwarder);
        consumer = address(new MockMulticallForwarderConsumer(forwarders));

        // Setup forwarder details
        typehashForwardRequest = keccak256(
            "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)"
        );
        nameHash = keccak256(bytes("GSNv2 Forwarder"));
        versionHash = keccak256(bytes("0.0.1"));
        typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        domainSeparator = keccak256(
            abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(forwarder))
        );

        vm.label(user1, "USER_1");
        vm.label(user2, "USER_2");
        vm.label(address(forwarder), "FORWARDER");
        vm.label(address(consumer), "CONSUMER");
    }

    function _signForwarderRequest(
        Forwarder.ForwardRequest memory forwardRequest,
        uint256 privateKey
    ) internal view returns (bytes memory) {
        bytes memory encodedRequest = abi.encode(
            typehashForwardRequest,
            forwardRequest.from,
            forwardRequest.to,
            forwardRequest.value,
            forwardRequest.gas,
            forwardRequest.nonce,
            keccak256(forwardRequest.data)
        );
        bytes32 structHash = keccak256(encodedRequest);
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, typedDataHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        return signature;
    }

    function test_multicall_callflow() public {
        // Make 3 calls to `increment` within a multicall
        bytes[] memory calls = new bytes[](3);
        calls[0] = abi.encodeWithSelector(MockMulticallForwarderConsumer.increment.selector);
        calls[1] = abi.encodeWithSelector(MockMulticallForwarderConsumer.increment.selector);
        calls[2] = abi.encodeWithSelector(MockMulticallForwarderConsumer.increment.selector);

        // CASE 1: multicall without using forwarder. Should increment counter for the caller i.e. `msg.sender`.

        assertEq(MockMulticallForwarderConsumer(consumer).counter(user1), 0);

        vm.prank(user1);
        Multicall(consumer).multicall(calls);

        assertEq(MockMulticallForwarderConsumer(consumer).counter(user1), 3); // counter incremented!

        // CASE 2: multicall with using forwarder. Should increment counter for the signer of the forwarder request.

        bytes memory multicallData = abi.encodeWithSelector(Multicall.multicall.selector, calls);

        Forwarder.ForwardRequest memory forwardRequest;

        forwardRequest.from = user1;
        forwardRequest.to = address(consumer);
        forwardRequest.value = 0;
        forwardRequest.gas = 100_000;
        forwardRequest.nonce = Forwarder(forwarder).getNonce(user1);
        forwardRequest.data = multicallData;

        bytes memory signature = _signForwarderRequest(forwardRequest, user1Pkey);

        Forwarder(forwarder).execute(forwardRequest, signature);

        assertEq(MockMulticallForwarderConsumer(consumer).counter(user1), 6); // counter incremented!

        // CASE 3: attempting to spoof address by manually appending address to multicall data arg.
        //
        //         Should REVERT(!) due to malformed calldata for the target function being called
        //         since the `multicall` function will append forward request signer's address to
        //         calldata regardless.
        bytes[] memory calls_spoof = new bytes[](3);
        calls_spoof[0] = abi.encodePacked(
            abi.encodeWithSelector(MockMulticallForwarderConsumer.increment.selector),
            user1
        );
        calls_spoof[1] = abi.encodePacked(
            abi.encodeWithSelector(MockMulticallForwarderConsumer.increment.selector),
            user1
        );
        calls_spoof[2] = abi.encodePacked(
            abi.encodeWithSelector(MockMulticallForwarderConsumer.increment.selector),
            user1
        );

        bytes memory multicallData_spoof = abi.encodeWithSelector(Multicall.multicall.selector, calls);

        // user2 spoofing as user1
        Forwarder.ForwardRequest memory forwardRequest_spoof;

        forwardRequest.from = user2;
        forwardRequest.to = address(consumer);
        forwardRequest.value = 0;
        forwardRequest.gas = 100_000;
        forwardRequest.nonce = Forwarder(forwarder).getNonce(user2);
        forwardRequest.data = multicallData_spoof;

        bytes memory signature_spoof = _signForwarderRequest(forwardRequest_spoof, user2Pkey);

        vm.expectRevert();
        Forwarder(forwarder).execute(forwardRequest_spoof, signature_spoof);

        assertEq(MockMulticallForwarderConsumer(consumer).counter(user1), 6); // counter unchanged!
        assertEq(MockMulticallForwarderConsumer(consumer).counter(user2), 0);
    }
}
