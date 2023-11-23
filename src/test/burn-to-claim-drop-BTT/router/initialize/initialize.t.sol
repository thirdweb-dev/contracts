// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../utils/BaseTest.sol";
import { BurnToClaimDropERC721 } from "contracts/prebuilts/unaudited/burn-to-claim-drop/BurnToClaimDropERC721.sol";
import { BurnToClaimDrop721Logic } from "contracts/prebuilts/unaudited/burn-to-claim-drop/extension/BurnToClaimDrop721Logic.sol";
import { PermissionsEnumerableImpl } from "contracts/extension/upgradeable/impl/PermissionsEnumerableImpl.sol";

import { ERC721AStorage } from "contracts/extension/upgradeable/init/ERC721AInit.sol";
import { ERC2771ContextStorage } from "contracts/extension/upgradeable/init/ERC2771ContextInit.sol";
import { ContractMetadataStorage } from "contracts/extension/upgradeable/init/ContractMetadataInit.sol";
import { OwnableStorage } from "contracts/extension/upgradeable/init/OwnableInit.sol";
import { PlatformFeeStorage } from "contracts/extension/upgradeable/init/PlatformFeeInit.sol";
import { RoyaltyStorage } from "contracts/extension/upgradeable/init/RoyaltyInit.sol";
import { PrimarySaleStorage } from "contracts/extension/upgradeable/init/PrimarySaleInit.sol";
import { PermissionsStorage } from "contracts/extension/upgradeable/init/PermissionsInit.sol";

import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract BurnToClaimDropERC721Router is BurnToClaimDropERC721 {
    constructor(Extension[] memory _extensions) BurnToClaimDropERC721(_extensions) {}

    function hasRole(bytes32 role, address addr) public view returns (bool) {
        return _hasRole(role, addr);
    }

    function roleAdmin(bytes32 role) public view returns (bytes32) {
        PermissionsStorage.Data storage data = PermissionsStorage.data();
        return data._getRoleAdmin[role];
    }

    function name() public view returns (string memory) {
        ERC721AStorage.Data storage data = ERC721AStorage.erc721AStorage();
        return data._name;
    }

    function symbol() public view returns (string memory) {
        ERC721AStorage.Data storage data = ERC721AStorage.erc721AStorage();
        return data._symbol;
    }

    function trustedForwarders(address[] memory _trustedForwarders) public view returns (bool) {
        ERC2771ContextStorage.Data storage data = ERC2771ContextStorage.data();

        for (uint256 i = 0; i < _trustedForwarders.length; i++) {
            if (!data.trustedForwarder[_trustedForwarders[i]]) {
                return false;
            }
        }
        return true;
    }

    function contractURI() public view returns (string memory) {
        ContractMetadataStorage.Data storage data = ContractMetadataStorage.data();
        return data.contractURI;
    }

    function owner() public view returns (address) {
        OwnableStorage.Data storage data = OwnableStorage.data();
        return data._owner;
    }

    function platformFeeRecipient() public view returns (address) {
        PlatformFeeStorage.Data storage data = PlatformFeeStorage.data();
        return data.platformFeeRecipient;
    }

    function platformFeeBps() public view returns (uint16) {
        PlatformFeeStorage.Data storage data = PlatformFeeStorage.data();
        return data.platformFeeBps;
    }

    function royaltyRecipient() public view returns (address) {
        RoyaltyStorage.Data storage data = RoyaltyStorage.data();
        return data.royaltyRecipient;
    }

    function royaltyBps() public view returns (uint16) {
        RoyaltyStorage.Data storage data = RoyaltyStorage.data();
        return data.royaltyBps;
    }

    function primarySaleRecipient() public view returns (address) {
        PrimarySaleStorage.Data storage data = PrimarySaleStorage.data();
        return data.recipient;
    }
}

contract BurnToClaimDropERC721_Initialize is BaseTest, IExtension {
    address public implementation;
    address public proxy;

    event ContractURIUpdated(string prevURI, string newURI);
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event PlatformFeeInfoUpdated(address indexed platformFeeRecipient, uint256 platformFeeBps);
    event DefaultRoyalty(address indexed newRoyaltyRecipient, uint256 newRoyaltyBps);
    event PrimarySaleRecipientUpdated(address indexed recipient);

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        Extension[] memory extensions = _setupExtensions(); // setup just a couple of extension/functions for testing here
        implementation = address(new BurnToClaimDropERC721Router(extensions));

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = address(
            new TWProxy(
                implementation,
                abi.encodeCall(
                    BurnToClaimDropERC721.initialize,
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

    function _setupExtensions() internal returns (Extension[] memory extensions) {
        extensions = new Extension[](2);

        // Extension: Permissions
        address permissions = address(new PermissionsEnumerableImpl());

        Extension memory extension_permissions;
        extension_permissions.metadata = ExtensionMetadata({
            name: "Permissions",
            metadataURI: "ipfs://Permissions",
            implementation: permissions
        });

        extension_permissions.functions = new ExtensionFunction[](1);
        extension_permissions.functions[0] = ExtensionFunction(
            Permissions.hasRole.selector,
            "hasRole(bytes32,address)"
        );

        extensions[0] = extension_permissions;

        address dropLogic = address(new BurnToClaimDrop721Logic());

        Extension memory extension_drop;
        extension_drop.metadata = ExtensionMetadata({
            name: "BurnToClaimDrop721Logic",
            metadataURI: "ipfs://BurnToClaimDrop721Logic",
            implementation: dropLogic
        });

        extension_drop.functions = new ExtensionFunction[](1);
        extension_drop.functions[0] = ExtensionFunction(BurnToClaimDrop721Logic.tokenURI.selector, "tokenURI(uint256)");
        extensions[1] = extension_drop;
    }

    function test_initialize_initializingImplementation() public {
        vm.expectRevert("Initializable: contract is already initialized");
        BurnToClaimDropERC721Router(payable(implementation)).initialize(
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
        BurnToClaimDropERC721Router(payable(proxy)).initialize(
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

    function test_initialize() public whenNotImplementation whenProxyNotInitialized {
        BurnToClaimDropERC721(payable(proxy)).initialize(
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
        BurnToClaimDropERC721Router router = BurnToClaimDropERC721Router(payable(proxy));
        assertEq(router.name(), NAME);
        assertEq(router.symbol(), SYMBOL);
        assertTrue(router.trustedForwarders(forwarders()));
        assertEq(router.platformFeeRecipient(), platformFeeRecipient);
        assertEq(router.platformFeeBps(), platformFeeBps);
        assertEq(router.royaltyRecipient(), royaltyRecipient);
        assertEq(router.royaltyBps(), royaltyBps);
        assertEq(router.primarySaleRecipient(), saleRecipient);
        assertTrue(router.hasRole(bytes32(0x00), deployer));
        assertTrue(router.hasRole(keccak256("TRANSFER_ROLE"), deployer));
        assertTrue(router.hasRole(keccak256("TRANSFER_ROLE"), address(0)));
        assertTrue(router.hasRole(keccak256("MINTER_ROLE"), deployer));
        assertTrue(router.hasRole(keccak256("EXTENSION_ROLE"), deployer));
        assertEq(router.roleAdmin(keccak256("EXTENSION_ROLE")), keccak256("EXTENSION_ROLE"));

        // check default extensions
        Extension[] memory _extensions = router.getAllExtensions();
        assertEq(_extensions.length, 2);
    }

    function test_initialize_event_ContractURIUpdated() public whenNotImplementation whenProxyNotInitialized {
        vm.expectEmit(false, false, false, true);
        emit ContractURIUpdated("", CONTRACT_URI);
        BurnToClaimDropERC721(payable(proxy)).initialize(
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

    function test_initialize_event_OwnerUpdated() public whenNotImplementation whenProxyNotInitialized {
        vm.expectEmit(true, true, false, false);
        emit OwnerUpdated(address(0), deployer);
        BurnToClaimDropERC721(payable(proxy)).initialize(
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

    function test_initialize_event_RoleGranted_DefaultAdmin() public whenNotImplementation whenProxyNotInitialized {
        bytes32 _defaultAdminRole = bytes32(0x00);
        vm.prank(deployer);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(_defaultAdminRole, deployer, deployer);
        BurnToClaimDropERC721(payable(proxy)).initialize(
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

    function test_initialize_event_RoleGranted_MinterRole() public whenNotImplementation whenProxyNotInitialized {
        bytes32 _minterRole = keccak256("MINTER_ROLE");
        vm.prank(deployer);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(_minterRole, deployer, deployer);
        BurnToClaimDropERC721(payable(proxy)).initialize(
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

    function test_initialize_event_RoleGranted_TransferRole() public whenNotImplementation whenProxyNotInitialized {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        vm.prank(deployer);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(_transferRole, deployer, deployer);
        BurnToClaimDropERC721(payable(proxy)).initialize(
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
    {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        vm.prank(deployer);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(_transferRole, address(0), deployer);
        BurnToClaimDropERC721(payable(proxy)).initialize(
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

    function test_initialize_event_RoleGranted_ExtensionRole() public whenNotImplementation whenProxyNotInitialized {
        bytes32 _extensionRole = keccak256("EXTENSION_ROLE");
        vm.prank(deployer);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(_extensionRole, deployer, deployer);
        BurnToClaimDropERC721(payable(proxy)).initialize(
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

    function test_initialize_event_RoleAdminChanged_ExtensionRole()
        public
        whenNotImplementation
        whenProxyNotInitialized
    {
        bytes32 _extensionRole = keccak256("EXTENSION_ROLE");
        vm.prank(deployer);
        vm.expectEmit(true, true, true, false);
        emit RoleAdminChanged(_extensionRole, bytes32(0x00), _extensionRole);
        BurnToClaimDropERC721(payable(proxy)).initialize(
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

    function test_initialize_event_PlatformFeeInfoUpdated() public whenNotImplementation whenProxyNotInitialized {
        vm.prank(deployer);
        vm.expectEmit(true, false, false, true);
        emit PlatformFeeInfoUpdated(platformFeeRecipient, platformFeeBps);
        BurnToClaimDropERC721(payable(proxy)).initialize(
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

    function test_initialize_event_DefaultRoyalty() public whenNotImplementation whenProxyNotInitialized {
        vm.prank(deployer);
        vm.expectEmit(true, false, false, true);
        emit DefaultRoyalty(royaltyRecipient, royaltyBps);
        BurnToClaimDropERC721(payable(proxy)).initialize(
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

    function test_initialize_event_PrimarySaleRecipientUpdated() public whenNotImplementation whenProxyNotInitialized {
        vm.prank(deployer);
        vm.expectEmit(true, false, false, false);
        emit PrimarySaleRecipientUpdated(saleRecipient);
        BurnToClaimDropERC721(payable(proxy)).initialize(
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
