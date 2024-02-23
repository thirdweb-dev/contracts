// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721, PlatformFee, Royalty } from "contracts/prebuilts/drop/DropERC721.sol";

// Test imports
import "../../../utils/BaseTest.sol";

contract DropERC721Test_initializer is BaseTest {
    DropERC721 public newDropContract;

    event ContractURIUpdated(string prevURI, string newURI);
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event PlatformFeeInfoUpdated(address indexed platformFeeRecipient, uint256 platformFeeBps);
    event DefaultRoyalty(address indexed newRoyaltyRecipient, uint256 newRoyaltyBps);
    event PrimarySaleRecipientUpdated(address indexed recipient);

    function setUp() public override {
        super.setUp();
    }

    modifier royaltyBPSTooHigh() {
        uint128 royaltyBps = 10001;
        _;
    }

    modifier platformFeeBPSTooHigh() {
        uint128 platformFeeBps = 10001;
        _;
    }

    function test_state() public {
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

        newDropContract = DropERC721(getContract("DropERC721"));
        (address _platformFeeRecipient, uint128 _platformFeeBps) = newDropContract.getPlatformFeeInfo();
        (address _royaltyRecipient, uint128 _royaltyBps) = newDropContract.getDefaultRoyaltyInfo();
        address _saleRecipient = newDropContract.primarySaleRecipient();

        for (uint256 i = 0; i < forwarders().length; i++) {
            assertEq(newDropContract.isTrustedForwarder(forwarders()[i]), true);
        }

        assertEq(newDropContract.name(), NAME);
        assertEq(newDropContract.symbol(), SYMBOL);
        assertEq(newDropContract.contractURI(), CONTRACT_URI);
        assertEq(newDropContract.owner(), deployer);
        assertEq(_platformFeeRecipient, platformFeeRecipient);
        assertEq(_platformFeeBps, platformFeeBps);
        assertEq(_royaltyRecipient, royaltyRecipient);
        assertEq(_royaltyBps, royaltyBps);
        assertEq(_saleRecipient, saleRecipient);
    }

    function test_revert_RoyaltyBPSTooHigh() public royaltyBPSTooHigh {
        vm.expectRevert(abi.encodeWithSelector(Royalty.RoyaltyExceededMaxFeeBps.selector, 10_000, 10_001));
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
                    10001,
                    platformFeeBps,
                    platformFeeRecipient
                )
            )
        );
    }

    function test_revert_PlatformFeeBPSTooHigh() public platformFeeBPSTooHigh {
        vm.expectRevert(abi.encodeWithSelector(PlatformFee.PlatformFeeExceededMaxFeeBps.selector, 10_000, 10_001));
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
                    10001,
                    platformFeeRecipient
                )
            )
        );
    }

    function test_event_ContractURIUpdated() public {
        vm.expectEmit(false, false, false, true);
        emit ContractURIUpdated("", CONTRACT_URI);
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

    function test_event_OwnerUpdated() public {
        vm.expectEmit(true, true, false, false);
        emit OwnerUpdated(address(0), deployer);
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

    function test_event_RoleGrantedDefaultAdminRole() public {
        bytes32 role = bytes32(0x00);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(role, deployer, factory);
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

    function test_event_RoleGrantedMinterRole() public {
        bytes32 role = keccak256("MINTER_ROLE");
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(role, deployer, factory);
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

    function test_event_RoleGrantedTransferRole() public {
        bytes32 role = keccak256("TRANSFER_ROLE");
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(role, deployer, factory);
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

    function test_event_RoleGrantedTransferRoleZeroAddress() public {
        bytes32 role = keccak256("TRANSFER_ROLE");
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(role, address(0), factory);
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

    function test_event_RoleGrantedMetadataRole() public {
        bytes32 role = keccak256("METADATA_ROLE");
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(role, deployer, factory);
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

    function test_event_RoleAdminChangedMetadataRole() public {
        bytes32 role = keccak256("METADATA_ROLE");
        vm.expectEmit(true, true, true, false);
        emit RoleAdminChanged(role, bytes32(0x00), role);
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

    function test_event_PlatformFeeInfoUpdated() public {
        vm.expectEmit(true, false, false, true);
        emit PlatformFeeInfoUpdated(platformFeeRecipient, platformFeeBps);
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

    function test_event_DefaultRoyalty() public {
        vm.expectEmit(true, false, false, true);
        emit DefaultRoyalty(royaltyRecipient, royaltyBps);
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

    function test_event_PrimarySaleRecipientUpdated() public {
        vm.expectEmit(true, false, false, false);
        emit PrimarySaleRecipientUpdated(saleRecipient);
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

    function test_roleCheck() public {
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

        newDropContract = DropERC721(getContract("DropERC721"));

        assertEq(newDropContract.hasRole(bytes32(0x00), deployer), true);
        assertEq(newDropContract.hasRole(keccak256("MINTER_ROLE"), deployer), true);
        assertEq(newDropContract.hasRole(keccak256("TRANSFER_ROLE"), deployer), true);
        assertEq(newDropContract.hasRole(keccak256("TRANSFER_ROLE"), address(0)), true);
        assertEq(newDropContract.hasRole(keccak256("METADATA_ROLE"), deployer), true);

        assertEq(newDropContract.getRoleAdmin(keccak256("METADATA_ROLE")), keccak256("METADATA_ROLE"));
    }
}
