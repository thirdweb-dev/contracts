// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Test imports
import "./utils/BaseTest.sol";
import "contracts/TWFactory.sol";
import "contracts/TWRegistry.sol";

// Helpers
import "contracts/TWProxy.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./utils/Console.sol";
import "./mocks/MockThirdwebContract.sol";

contract TWProxyBenchmark is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function testBenchmark_deployDrop721() public {
        deployContractProxy(
            "DropERC721",
            abi.encodeCall(
                DropERC721.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    royaltyRecipient,
                    royaltyBps,
                    platformFeeBps,
                    platformFeeRecipient
                )
            )
        );
    }

    function testBenchmark_deployDrop1155() public {
        deployContractProxy(
            "DropERC1155",
            abi.encodeCall(
                DropERC1155.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    royaltyRecipient,
                    royaltyBps,
                    platformFeeBps,
                    platformFeeRecipient
                )
            )
        );
    }

    function testBenchmark_deployToken721() public {
        deployContractProxy(
            "TokenERC721",
            abi.encodeCall(
                TokenERC721.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    royaltyRecipient,
                    royaltyBps,
                    platformFeeBps,
                    platformFeeRecipient
                )
            )
        );
    }

    function testBenchmark_deployToken1155() public {
        deployContractProxy(
            "TokenERC1155",
            abi.encodeCall(
                TokenERC1155.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    royaltyRecipient,
                    royaltyBps,
                    platformFeeBps,
                    platformFeeRecipient
                )
            )
        );
    }
}
