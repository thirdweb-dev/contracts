// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC721 is TokenERC721 {
    function eip712NameHash() external view returns (bytes32) {
        return _EIP712NameHash();
    }

    function eip712VersionHash() external view returns (bytes32) {
        return _EIP712VersionHash();
    }
}

contract TokenERC721Test_Initialize is BaseTest {
    address public implementation;
    address public proxy;

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC721());

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = address(
            new TWProxy(
                implementation,
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
            )
        );
    }

    function test_initialize_initializingImplementation() public {
        vm.expectRevert("Initializable: contract is already initialized");
        TokenERC721(implementation).initialize(
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
        );
    }

    modifier whenNotImplementation() {
        _;
    }

    function test_initialize_proxyAlreadyInitialized() public whenNotImplementation {
        vm.expectRevert("Initializable: contract is already initialized");
        MyTokenERC721(proxy).initialize(
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
        );
    }

    modifier whenProxyNotInitialized() {
        proxy = address(new TWProxy(implementation, ""));
        _;
    }

    function test_initialize_exceedsMaxBps() public whenNotImplementation whenProxyNotInitialized {
        vm.expectRevert("exceeds MAX_BPS");
        MyTokenERC721(proxy).initialize(
            deployer,
            NAME,
            SYMBOL,
            CONTRACT_URI,
            forwarders(),
            saleRecipient,
            royaltyRecipient,
            royaltyBps,
            uint128(MAX_BPS) + 1, // platformFeeBps greater than MAX_BPS
            platformFeeRecipient
        );
    }

    modifier whenPlatformFeeBpsWithinMaxBps() {
        _;
    }

    function test_initialize() public whenNotImplementation whenProxyNotInitialized whenPlatformFeeBpsWithinMaxBps {
        MyTokenERC721(proxy).initialize(
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
        );

        // check state
        MyTokenERC721 tokenContract = MyTokenERC721(proxy);

        assertEq(tokenContract.eip712NameHash(), keccak256(bytes("TokenERC721")));
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
        assertEq(tokenContract.platformFeeRecipient(), platformFeeRecipient);

        (address _royaltyRecipient, uint16 _royaltyBps) = tokenContract.getDefaultRoyaltyInfo();
        (address _royaltyRecipientForToken, uint16 _royaltyBpsForToken) = tokenContract.getRoyaltyInfoForToken(1); // random tokenId
        assertEq(_royaltyBps, royaltyBps);
        assertEq(_royaltyRecipient, royaltyRecipient);
        assertEq(_royaltyRecipient, _royaltyRecipientForToken);
        assertEq(_royaltyBps, _royaltyBpsForToken);

        assertEq(tokenContract.primarySaleRecipient(), saleRecipient);

        assertEq(tokenContract.owner(), deployer);
        assertTrue(tokenContract.hasRole(bytes32(0x00), deployer));
        assertTrue(tokenContract.hasRole(keccak256("TRANSFER_ROLE"), deployer));
        assertTrue(tokenContract.hasRole(keccak256("TRANSFER_ROLE"), address(0)));
        assertTrue(tokenContract.hasRole(keccak256("MINTER_ROLE"), deployer));
        assertTrue(tokenContract.hasRole(keccak256("METADATA_ROLE"), deployer));
        assertEq(tokenContract.getRoleAdmin(keccak256("METADATA_ROLE")), keccak256("METADATA_ROLE"));
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
        MyTokenERC721(proxy).initialize(
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
        MyTokenERC721(proxy).initialize(
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
        MyTokenERC721(proxy).initialize(
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
        MyTokenERC721(proxy).initialize(
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
        );
    }

    function test_initialize_event_RoleGranted_MetadataRole()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenPlatformFeeBpsWithinMaxBps
    {
        bytes32 _metadataRole = keccak256("METADATA_ROLE");
        vm.prank(deployer);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(_metadataRole, deployer, deployer);
        MyTokenERC721(proxy).initialize(
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
        );
    }

    function test_initialize_event_RoleAdminChanged_MetadataRole()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenPlatformFeeBpsWithinMaxBps
    {
        bytes32 _metadataRole = keccak256("METADATA_ROLE");
        vm.prank(deployer);
        vm.expectEmit(true, true, true, false);
        emit RoleAdminChanged(_metadataRole, bytes32(0x00), _metadataRole);
        MyTokenERC721(proxy).initialize(
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
        );
    }
}
