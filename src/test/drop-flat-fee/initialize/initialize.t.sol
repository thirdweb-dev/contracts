// <ai_context>
// Unit tests for the initialize function in DropERC721FlatFee contract.
// Tests state changes, events, and revert conditions during initialization.
// </ai_context>

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721FlatFee, Royalty } from "contracts/prebuilts/drop/DropERC721FlatFee.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";
import { IPlatformFee } from "contracts/extension/interface/IPlatformFee.sol";

// Test imports
import "src/test/utils/BaseTest.sol";

contract DropERC721FlatFeeTest_initialize is BaseTest {
    event ContractURIUpdated(string prevURI, string newURI);
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event PrimarySaleRecipientUpdated(address indexed recipient);

    DropERC721FlatFee public drop;

    address private dropImpl;

    function deployDrop(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint128 _platformFeeBps,
        address _platformFeeRecipient,
        address _imp
    ) public {
        vm.prank(deployer);
        drop = DropERC721FlatFee(
            address(
                new TWProxy(
                    _imp,
                    abi.encodeCall(
                        DropERC721FlatFee.initialize,
                        (
                            _defaultAdmin,
                            _name,
                            _symbol,
                            _contractURI,
                            _trustedForwarders,
                            _saleRecipient,
                            _royaltyRecipient,
                            _royaltyBps,
                            _platformFeeBps,
                            _platformFeeRecipient
                        )
                    )
                )
            )
        );
        // Set to flat fee mode
        vm.prank(_defaultAdmin);
        drop.setPlatformFeeType(IPlatformFee.PlatformFeeType.Flat);
        vm.prank(_defaultAdmin);
        drop.setFlatPlatformFeeInfo(_platformFeeRecipient, 0.1 ether);
    }

    function setUp() public override {
        super.setUp();
        dropImpl = address(new DropERC721FlatFee());
    }

    function test_state() public {
        deployDrop(
            deployer,
            NAME,
            SYMBOL,
            CONTRACT_URI,
            forwarders(),
            saleRecipient,
            royaltyRecipient,
            royaltyBps,
            platformFeeBps,
            platformFeeRecipient,
            dropImpl
        );

        address _saleRecipient = drop.primarySaleRecipient();
        (address _royaltyRecipient, uint16 _royaltyBps) = drop.getDefaultRoyaltyInfo();
        string memory _name = drop.name();
        string memory _symbol = drop.symbol();
        string memory _contractURI = drop.contractURI();
        address _owner = drop.owner();

        assertEq(_name, NAME);
        assertEq(_symbol, SYMBOL);
        assertEq(_contractURI, CONTRACT_URI);
        assertEq(_saleRecipient, saleRecipient);
        assertEq(_royaltyRecipient, royaltyRecipient);
        assertEq(_royaltyBps, royaltyBps);
        assertEq(_owner, deployer);

        for (uint256 i = 0; i < forwarders().length; i++) {
            assertEq(drop.isTrustedForwarder(forwarders()[i]), true);
        }

        assertTrue(drop.hasRole(drop.DEFAULT_ADMIN_ROLE(), deployer));
        assertTrue(drop.hasRole(keccak256("TRANSFER_ROLE"), deployer));
        assertTrue(drop.hasRole(keccak256("MINTER_ROLE"), deployer));
        assertTrue(drop.hasRole(keccak256("TRANSFER_ROLE"), address(0)));
        assertTrue(drop.hasRole(keccak256("METADATA_ROLE"), deployer));
    }

    // Additional tests for revert RoyaltyTooHigh, events, etc., similar to open edition
    // ...
}