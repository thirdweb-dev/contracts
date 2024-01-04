// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@std/Test.sol";

import { Multicall } from "contracts/extension/Multicall.sol";
import { Forwarder } from "contracts/infra/forwarder/Forwarder.sol";
import { ERC2771Context } from "contracts/extension/upgradeable/ERC2771Context.sol";
import { TokenERC721 } from "contracts/prebuilts/token/TokenERC721.sol";
import { Strings } from "contracts/lib/Strings.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

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
    TokenERC721 internal token;

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

        // Deploy `TokenERC721`
        address impl = address(new TokenERC721());
        token = TokenERC721(
            address(
                new TWProxy(
                    impl,
                    abi.encodeWithSelector(
                        TokenERC721.initialize.selector,
                        user1,
                        "name",
                        "SYMBOL",
                        "ipfs://",
                        forwarders,
                        user1,
                        user1,
                        0,
                        0,
                        user1
                    )
                )
            )
        );

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

    function test_multicall_viaDirectCall() public {
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
    }

    function test_multicall_viaForwarder() public {
        // Make 3 calls to `increment` within a multicall
        bytes[] memory calls = new bytes[](3);
        calls[0] = abi.encodeWithSelector(MockMulticallForwarderConsumer.increment.selector);
        calls[1] = abi.encodeWithSelector(MockMulticallForwarderConsumer.increment.selector);
        calls[2] = abi.encodeWithSelector(MockMulticallForwarderConsumer.increment.selector);

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

        assertEq(MockMulticallForwarderConsumer(consumer).counter(user1), 3); // counter incremented!
    }

    function test_multicall_viaForwarder_attemptSpoof() public {
        // Make 3 calls to `increment` within a multicall
        bytes[] memory callsSpoof = new bytes[](3);
        callsSpoof[0] = abi.encodePacked(
            abi.encodeWithSelector(MockMulticallForwarderConsumer.increment.selector),
            user1
        );
        callsSpoof[1] = abi.encodePacked(
            abi.encodeWithSelector(MockMulticallForwarderConsumer.increment.selector),
            user1
        );
        callsSpoof[2] = abi.encodePacked(
            abi.encodeWithSelector(MockMulticallForwarderConsumer.increment.selector),
            user1
        );

        // CASE 3: attempting to spoof address by manually appending address to multicall data arg.
        //
        //         This attempt fails because `multicall` enforces original forwarder request signer
        //         as the `_msgSender()`.

        bytes memory multicallDataSpoof = abi.encodeWithSelector(Multicall.multicall.selector, callsSpoof);

        // user2 spoofing as user1
        Forwarder.ForwardRequest memory forwardRequestSpoof;

        forwardRequestSpoof.from = user2;
        forwardRequestSpoof.to = address(consumer);
        forwardRequestSpoof.value = 0;
        forwardRequestSpoof.gas = 100_000;
        forwardRequestSpoof.nonce = Forwarder(forwarder).getNonce(user2);
        forwardRequestSpoof.data = multicallDataSpoof;

        bytes memory signatureSpoof = _signForwarderRequest(forwardRequestSpoof, user2Pkey);

        // vm.expectRevert();
        Forwarder(forwarder).execute(forwardRequestSpoof, signatureSpoof);

        assertEq(MockMulticallForwarderConsumer(consumer).counter(user1), 0); // counter unchanged!
        assertEq(MockMulticallForwarderConsumer(consumer).counter(user2), 3); // counter incremented for forwarder request signer!
    }

    function test_multicall_tokenerc721_viaForwarder_attemptSpoof() public {
        // User1 is admin on `token`
        assertTrue(token.hasRole(keccak256("MINTER_ROLE"), user1));

        // token ID `0` has no owner
        vm.expectRevert("ERC721: invalid token ID");
        token.ownerOf(0);

        // Make call to `mintTo` within a multicall
        bytes[] memory callsSpoof = new bytes[](1);
        callsSpoof[0] = abi.encodePacked(
            abi.encodeWithSelector(TokenERC721.mintTo.selector, user2, "metadataURI"),
            user1
        );
        // CASE:   attempting to spoof address by manually appending address to multicall data arg.
        //
        //         This attempt fails because `multicall` enforces original forwarder request signer
        //         as the `_msgSender()`.

        bytes memory multicallDataSpoof = abi.encodeWithSelector(Multicall.multicall.selector, callsSpoof);

        // user2 spoofing as user1
        Forwarder.ForwardRequest memory forwardRequestSpoof;

        forwardRequestSpoof.from = user2;
        forwardRequestSpoof.to = address(token);
        forwardRequestSpoof.value = 0;
        forwardRequestSpoof.gas = 100_000;
        forwardRequestSpoof.nonce = Forwarder(forwarder).getNonce(user2);
        forwardRequestSpoof.data = multicallDataSpoof;

        bytes memory signatureSpoof = _signForwarderRequest(forwardRequestSpoof, user2Pkey);

        // Minter role check occurs on user2 i.e. signer of the forwarder request, and not user1 i.e. the address user2 attempts to spoof.
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(user2), 20),
                " is missing role ",
                Strings.toHexString(uint256(keccak256("MINTER_ROLE")), 32)
            )
        );
        Forwarder(forwarder).execute(forwardRequestSpoof, signatureSpoof);

        // token ID `0` still has no owner
        vm.expectRevert("ERC721: invalid token ID");
        token.ownerOf(0);
    }
}
