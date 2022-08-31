// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/ForwarderConsumer.sol";
import "contracts/ForwarderNoChainId.sol";

import "./utils/BaseTest.sol";

contract ForwarderNoChainIdTest is BaseTest {
    address public forwarderNoChainId;
    ForwarderConsumer public consumer;

    uint256 public userPKey = 1020;
    address public user;
    address public relayer = address(0x4567);

    bytes32 internal typehashForwardRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        user = vm.addr(userPKey);
        consumer = new ForwarderConsumer(forwarder);

        forwarderNoChainId = address(new ForwarderNoChainId());
        consumer = new ForwarderConsumer(forwarderNoChainId);

        typehashForwardRequest = keccak256(
            "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,uint256 chainid)"
        );
        nameHash = keccak256(bytes("MinimalForwarder"));
        versionHash = keccak256(bytes("0.0.1"));
        typehashEip712 = keccak256("EIP712Domain(string name,string version,address verifyingContract)");
        domainSeparator = keccak256(abi.encode(typehashEip712, nameHash, versionHash, forwarderNoChainId));

        vm.label(user, "End user");
        vm.label(forwarder, "Forwarder");
        vm.label(relayer, "Relayer");
        vm.label(address(consumer), "Consumer");
    }

    /*///////////////////////////////////////////////////////////////
       Updated `Forwarder`: chainId in ForwardRequest, not typehash.
    //////////////////////////////////////////////////////////////*/

    function signForwarderRequest(ForwarderNoChainId.ForwardRequest memory forwardRequest, uint256 privateKey)
        internal
        returns (bytes memory)
    {
        bytes memory encodedRequest = abi.encode(
            typehashForwardRequest,
            forwardRequest.from,
            forwardRequest.to,
            forwardRequest.value,
            forwardRequest.gas,
            forwardRequest.nonce,
            keccak256(forwardRequest.data),
            forwardRequest.chainid
        );
        bytes32 structHash = keccak256(encodedRequest);
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, typedDataHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        return signature;
    }

    function test_state_forwarderNoChainId() public {
        ForwarderNoChainId.ForwardRequest memory forwardRequest;

        forwardRequest.from = user;
        forwardRequest.to = address(consumer);
        forwardRequest.value = 0;
        forwardRequest.gas = 100_000;
        forwardRequest.nonce = ForwarderNoChainId(forwarderNoChainId).getNonce(user);
        forwardRequest.data = abi.encodeCall(ForwarderConsumer.setCaller, ());
        forwardRequest.chainid = block.chainid;

        bytes memory signature = signForwarderRequest(forwardRequest, userPKey);
        vm.prank(relayer);
        ForwarderNoChainId(forwarderNoChainId).execute(forwardRequest, signature);

        assertEq(consumer.caller(), user);
    }
}
