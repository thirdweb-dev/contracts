// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC20 is TokenERC20 {
    function eip712NameHash() external view returns (bytes32) {
        return _EIP712NameHash();
    }

    function eip712VersionHash() external view returns (bytes32) {
        return _EIP712VersionHash();
    }
}

contract TokenERC20Test_Initialize is BaseTest {
    address public implementation;
    address public proxy;

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC20());

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = address(
            new TWProxy(
                implementation,
                abi.encodeCall(
                    TokenERC20.initialize,
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
            )
        );
    }

    function test_initialize_initializingImplementation() public {
        vm.expectRevert("Initializable: contract is already initialized");
        TokenERC20(implementation).initialize(
            deployer,
            NAME,
            SYMBOL,
            CONTRACT_URI,
            forwarders(),
            saleRecipient,
            platformFeeRecipient,
            platformFeeBps
        );
    }

    modifier whenNotImplementation() {
        _;
    }

    function test_initialize_proxyAlreadyInitialized() public whenNotImplementation {
        vm.expectRevert("Initializable: contract is already initialized");
        MyTokenERC20(proxy).initialize(
            deployer,
            NAME,
            SYMBOL,
            CONTRACT_URI,
            forwarders(),
            saleRecipient,
            platformFeeRecipient,
            platformFeeBps
        );
    }

    modifier whenProxyNotInitialized() {
        proxy = address(new TWProxy(implementation, ""));
        _;
    }

    function test_initialize_exceedsMaxBps() public whenNotImplementation whenProxyNotInitialized {
        vm.expectRevert("exceeds MAX_BPS");
        MyTokenERC20(proxy).initialize(
            deployer,
            NAME,
            SYMBOL,
            CONTRACT_URI,
            forwarders(),
            saleRecipient,
            platformFeeRecipient,
            uint128(MAX_BPS) + 1 // platformFeeBps greater than MAX_BPS
        );
    }

    modifier whenPlatformFeeBpsWithinMaxBps() {
        _;
    }

    function test_initialize() public whenNotImplementation whenProxyNotInitialized whenPlatformFeeBpsWithinMaxBps {
        MyTokenERC20(proxy).initialize(
            deployer,
            NAME,
            SYMBOL,
            CONTRACT_URI,
            forwarders(),
            saleRecipient,
            platformFeeRecipient,
            platformFeeBps
        );

        // check state
        MyTokenERC20 tokenContract = MyTokenERC20(proxy);

        assertEq(tokenContract.eip712NameHash(), keccak256(bytes(NAME)));
        assertEq(tokenContract.eip712VersionHash(), keccak256(bytes("1")));

        address[] memory _trustedForwarders = forwarders();
        for (uint256 i = 0; i < _trustedForwarders.length; i++) {
            assertTrue(tokenContract.isTrustedForwarder(_trustedForwarders[i]));
        }

        assertEq(tokenContract.name(), NAME);
        assertEq(tokenContract.symbol(), SYMBOL);
        assertEq(tokenContract.contractURI(), CONTRACT_URI);

        (address _platformFeeRecipient, uint16 _platformFeeBps) = tokenContract.getPlatformFeeInfo();
        assertEq(_platformFeeBps, platformFeeBps);
        assertEq(_platformFeeRecipient, platformFeeRecipient);

        assertEq(tokenContract.primarySaleRecipient(), saleRecipient);

        assertTrue(tokenContract.hasRole(bytes32(0x00), deployer));
        assertTrue(tokenContract.hasRole(keccak256("TRANSFER_ROLE"), deployer));
        assertTrue(tokenContract.hasRole(keccak256("TRANSFER_ROLE"), address(0)));
        assertTrue(tokenContract.hasRole(keccak256("MINTER_ROLE"), deployer));
    }

    function test_initialize_event_RoleGranted_DefaultAdmin()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenPlatformFeeBpsWithinMaxBps
    {
        bytes32 _defaultAdminRole = bytes32(0x00);
        vm.prank(deployer);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(_defaultAdminRole, deployer, deployer);
        MyTokenERC20(proxy).initialize(
            deployer,
            NAME,
            SYMBOL,
            CONTRACT_URI,
            forwarders(),
            saleRecipient,
            platformFeeRecipient,
            platformFeeBps
        );
    }

    function test_initialize_event_RoleGranted_MinterRole()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenPlatformFeeBpsWithinMaxBps
    {
        bytes32 _minterRole = keccak256("MINTER_ROLE");
        vm.prank(deployer);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(_minterRole, deployer, deployer);
        MyTokenERC20(proxy).initialize(
            deployer,
            NAME,
            SYMBOL,
            CONTRACT_URI,
            forwarders(),
            saleRecipient,
            platformFeeRecipient,
            platformFeeBps
        );
    }

    function test_initialize_event_RoleGranted_TransferRole()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenPlatformFeeBpsWithinMaxBps
    {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        vm.prank(deployer);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(_transferRole, deployer, deployer);
        MyTokenERC20(proxy).initialize(
            deployer,
            NAME,
            SYMBOL,
            CONTRACT_URI,
            forwarders(),
            saleRecipient,
            platformFeeRecipient,
            platformFeeBps
        );
    }

    function test_initialize_event_RoleGranted_TransferRole_AddressZero()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenPlatformFeeBpsWithinMaxBps
    {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        vm.prank(deployer);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(_transferRole, address(0), deployer);
        MyTokenERC20(proxy).initialize(
            deployer,
            NAME,
            SYMBOL,
            CONTRACT_URI,
            forwarders(),
            saleRecipient,
            platformFeeRecipient,
            platformFeeBps
        );
    }
}
