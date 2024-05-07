// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC20, PlatformFee } from "contracts/prebuilts/drop/DropERC20.sol";

// Test imports
import "../../../utils/BaseTest.sol";

contract DropERC20Test_initializer is BaseTest {
    DropERC20 public newDropContract;

    event ContractURIUpdated(string prevURI, string newURI);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event PlatformFeeInfoUpdated(address indexed platformFeeRecipient, uint256 platformFeeBps);
    event PrimarySaleRecipientUpdated(address indexed recipient);

    function setUp() public override {
        super.setUp();
    }

    modifier platformFeeBPSTooHigh() {
        platformFeeBps = 10001;
        _;
    }

    function test_state() public {
        deployContractProxy(
            "DropERC20",
            abi.encodeCall(
                DropERC20.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    platformFeeRecipient,
                    platformFeeBps
                )
            )
        );

        newDropContract = DropERC20(getContract("DropERC20"));
        (address _platformFeeRecipient, uint128 _platformFeeBps) = newDropContract.getPlatformFeeInfo();
        address _saleRecipient = newDropContract.primarySaleRecipient();

        for (uint256 i = 0; i < forwarders().length; i++) {
            assertEq(newDropContract.isTrustedForwarder(forwarders()[i]), true);
        }

        assertEq(newDropContract.name(), NAME);
        assertEq(newDropContract.symbol(), SYMBOL);
        assertEq(newDropContract.contractURI(), CONTRACT_URI);
        assertEq(_platformFeeRecipient, platformFeeRecipient);
        assertEq(_platformFeeBps, platformFeeBps);
        assertEq(_saleRecipient, saleRecipient);
    }

    function test_revert_PlatformFeeBPSTooHigh() public platformFeeBPSTooHigh {
        vm.expectRevert(
            abi.encodeWithSelector(PlatformFee.PlatformFeeExceededMaxFeeBps.selector, 10_000, platformFeeBps)
        );
        deployContractProxy(
            "DropERC20",
            abi.encodeCall(
                DropERC20.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    platformFeeRecipient,
                    platformFeeBps
                )
            )
        );
    }

    function test_event_ContractURIUpdated() public {
        vm.expectEmit(false, false, false, true);
        emit ContractURIUpdated("", CONTRACT_URI);
        deployContractProxy(
            "DropERC20",
            abi.encodeCall(
                DropERC20.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    platformFeeRecipient,
                    platformFeeBps
                )
            )
        );
    }

    function test_event_RoleGrantedDefaultAdminRole() public {
        bytes32 role = bytes32(0x00);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(role, deployer, factory);
        deployContractProxy(
            "DropERC20",
            abi.encodeCall(
                DropERC20.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    platformFeeRecipient,
                    platformFeeBps
                )
            )
        );
    }

    function test_event_RoleGrantedTransferRole() public {
        bytes32 role = keccak256("TRANSFER_ROLE");
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(role, deployer, factory);
        deployContractProxy(
            "DropERC20",
            abi.encodeCall(
                DropERC20.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    platformFeeRecipient,
                    platformFeeBps
                )
            )
        );
    }

    function test_event_RoleGrantedTransferRoleZeroAddress() public {
        bytes32 role = keccak256("TRANSFER_ROLE");
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(role, address(0), factory);
        deployContractProxy(
            "DropERC20",
            abi.encodeCall(
                DropERC20.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    platformFeeRecipient,
                    platformFeeBps
                )
            )
        );
    }

    function test_event_PlatformFeeInfoUpdated() public {
        vm.expectEmit(true, false, false, true);
        emit PlatformFeeInfoUpdated(platformFeeRecipient, platformFeeBps);
        deployContractProxy(
            "DropERC20",
            abi.encodeCall(
                DropERC20.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    platformFeeRecipient,
                    platformFeeBps
                )
            )
        );
    }

    function test_event_PrimarySaleRecipientUpdated() public {
        vm.expectEmit(true, false, false, false);
        emit PrimarySaleRecipientUpdated(saleRecipient);
        deployContractProxy(
            "DropERC20",
            abi.encodeCall(
                DropERC20.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    platformFeeRecipient,
                    platformFeeBps
                )
            )
        );
    }

    function test_roleCheck() public {
        deployContractProxy(
            "DropERC20",
            abi.encodeCall(
                DropERC20.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    platformFeeRecipient,
                    platformFeeBps
                )
            )
        );

        newDropContract = DropERC20(getContract("DropERC20"));

        assertEq(newDropContract.hasRole(bytes32(0x00), deployer), true);
        assertEq(newDropContract.hasRole(keccak256("TRANSFER_ROLE"), deployer), true);
        assertEq(newDropContract.hasRole(keccak256("TRANSFER_ROLE"), address(0)), true);
    }
}
