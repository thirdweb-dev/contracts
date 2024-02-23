// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { OpenEditionERC721FlatFee, Royalty } from "contracts/prebuilts/open-edition/OpenEditionERC721FlatFee.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import "src/test/utils/BaseTest.sol";

contract OpenEditionERC721FlatFeeTest_initialize is BaseTest {
    event ContractURIUpdated(string prevURI, string newURI);
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event PrimarySaleRecipientUpdated(address indexed recipient);

    OpenEditionERC721FlatFee public openEdition;

    address private openEditionImpl;

    function deployOpenEdition(
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
        openEdition = OpenEditionERC721FlatFee(
            address(
                new TWProxy(
                    _imp,
                    abi.encodeCall(
                        OpenEditionERC721FlatFee.initialize,
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
    }

    function setUp() public override {
        super.setUp();
        openEditionImpl = address(new OpenEditionERC721FlatFee());
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: initialize
    //////////////////////////////////////////////////////////////*/

    function test_state() public {
        deployOpenEdition(
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
            openEditionImpl
        );

        address _saleRecipient = openEdition.primarySaleRecipient();
        (address _royaltyRecipient, uint16 _royaltyBps) = openEdition.getDefaultRoyaltyInfo();
        string memory _name = openEdition.name();
        string memory _symbol = openEdition.symbol();
        string memory _contractURI = openEdition.contractURI();
        address _owner = openEdition.owner();

        assertEq(_name, NAME);
        assertEq(_symbol, SYMBOL);
        assertEq(_contractURI, CONTRACT_URI);
        assertEq(_saleRecipient, saleRecipient);
        assertEq(_royaltyRecipient, royaltyRecipient);
        assertEq(_royaltyBps, royaltyBps);
        assertEq(_owner, deployer);

        for (uint256 i = 0; i < forwarders().length; i++) {
            assertEq(openEdition.isTrustedForwarder(forwarders()[i]), true);
        }

        assertTrue(openEdition.hasRole(openEdition.DEFAULT_ADMIN_ROLE(), deployer));
        assertTrue(openEdition.hasRole(keccak256("TRANSFER_ROLE"), deployer));
        assertTrue(openEdition.hasRole(keccak256("MINTER_ROLE"), deployer));
        assertTrue(openEdition.hasRole(keccak256("TRANSFER_ROLE"), address(0)));
    }

    function test_revert_RoyaltyTooHigh() public {
        uint128 _royaltyBps = 10001;

        vm.expectRevert(abi.encodeWithSelector(Royalty.RoyaltyExceededMaxFeeBps.selector, 10_000, _royaltyBps));
        deployOpenEdition(
            deployer,
            NAME,
            SYMBOL,
            CONTRACT_URI,
            forwarders(),
            saleRecipient,
            royaltyRecipient,
            _royaltyBps,
            platformFeeBps,
            platformFeeRecipient,
            openEditionImpl
        );
    }

    function test_event_ContractURIUpdated() public {
        vm.expectEmit(false, false, false, true);
        emit ContractURIUpdated("", CONTRACT_URI);
        deployOpenEdition(
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
            openEditionImpl
        );
    }

    function test_event_OwnerUpdated() public {
        vm.expectEmit(true, true, false, false);
        emit OwnerUpdated(address(0), deployer);
        deployOpenEdition(
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
            openEditionImpl
        );
    }

    function test_event_TransferRoleAddressZero() public {
        bytes32 role = keccak256("TRANSFER_ROLE");
        vm.expectEmit(true, true, false, false);
        emit RoleGranted(role, address(0), deployer);
        deployOpenEdition(
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
            openEditionImpl
        );
    }

    function test_event_TransferRoleAdmin() public {
        bytes32 role = keccak256("TRANSFER_ROLE");
        vm.expectEmit(true, true, false, false);
        emit RoleGranted(role, deployer, deployer);
        deployOpenEdition(
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
            openEditionImpl
        );
    }

    function test_event_MinterRoleAdmin() public {
        bytes32 role = keccak256("MINTER_ROLE");
        vm.expectEmit(true, true, false, false);
        emit RoleGranted(role, deployer, deployer);
        deployOpenEdition(
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
            openEditionImpl
        );
    }

    function test_event_DefaultAdminRoleAdmin() public {
        bytes32 role = bytes32(0x00);
        vm.expectEmit(true, true, false, false);
        emit RoleGranted(role, deployer, deployer);
        deployOpenEdition(
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
            openEditionImpl
        );
    }

    function test_event_PrimarysaleRecipientUpdated() public {
        vm.expectEmit(true, false, false, false);
        emit PrimarySaleRecipientUpdated(saleRecipient);
        deployOpenEdition(
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
            openEditionImpl
        );
    }
}
