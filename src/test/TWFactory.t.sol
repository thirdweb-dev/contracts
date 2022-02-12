// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test imports
import "./utils/BaseTest.sol";
import "contracts/TWFactory.sol";
import "contracts/TWRegistry.sol";

// Helpers
import "contracts/TWProxy.sol";
import "contracts/interfaces/IThirdwebModule.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./utils/Console.sol";

contract MockThirdwebModule is IThirdwebModule {
    string public contractURI;

    function moduleType() external pure returns (bytes32) {
        return bytes32("MOCK");
    }

    function version() external pure returns (uint8) {
        return 1;
    }

    function setContractURI(string calldata _uri) external {
        contractURI = _uri;
    }
}

interface ITWFactoryData {
    event ProxyDeployed(address indexed implementation, address proxy, address indexed deployer);
    event NewModuleImplementation(bytes32 indexed moduleType, uint256 version, address implementation);
    event ImplementationApproved(address implementation, bool isApproved);
}

contract TWFactoryTest is ITWFactoryData, BaseTest {
    // Target contract
    TWFactory internal twFactory;

    // Secondary contracts
    MockThirdwebModule internal mockModule;

    // Actors
    address internal factoryDeployer = address(0x1);
    address internal moduleDeployer = address(0x20);
    address internal moduleDeployer2 = address(0x21);

    // Test params
    address internal trustedForwarder = address(0x3);
    address internal mockUnapprovedImplementation = address(0x5);

    //  =====   Set up  =====

    function setUp() public {
        vm.prank(factoryDeployer);
        twFactory = new TWFactory(trustedForwarder);

        vm.prank(moduleDeployer);
        mockModule = new MockThirdwebModule();
    }

    //  =====   Initial state   =====

    /**
     *  @dev Tests the relevant initial state of the contract.
     *
     *  - Deployer of the contract has `FACTORY_ROLE`
     */
    function test_initialState() public {
        assertTrue(twFactory.hasRole(twFactory.FACTORY_ROLE(), factoryDeployer));
    }

    //  =====   Functionality tests   =====

    /// @dev Test `addModuleImplementation`

    function test_addModuleImplementation() public {
        bytes32 moduleType = mockModule.moduleType();
        uint256 moduleVersion = mockModule.version();
        uint256 moduleVersionOnFactory = twFactory.currentModuleVersion(moduleType);

        vm.prank(factoryDeployer);
        twFactory.addModuleImplementation(moduleType, address(mockModule));

        assertTrue(twFactory.implementationApproval(address(mockModule)));
        assertEq(address(mockModule), twFactory.modules(moduleType, moduleVersion));
        assertEq(twFactory.currentModuleVersion(moduleType), moduleVersionOnFactory + 1);
        assertEq(twFactory.getImplementation(moduleType, moduleVersion), address(mockModule));
    }

    function test_addModuleImplementation_revert_invalidCaller() public {
        bytes32 moduleType = mockModule.moduleType();

        vm.expectRevert("not admin.");

        vm.prank(moduleDeployer);
        twFactory.addModuleImplementation(moduleType, address(mockModule));
    }

    function test_addModuleImplementation_revert_invalidModuleType() public {
        bytes32 moduleType = bytes32("Random");

        assertTrue(mockModule.moduleType() != moduleType);

        vm.expectRevert("invalid module type.");

        vm.prank(factoryDeployer);
        twFactory.addModuleImplementation(moduleType, address(mockModule));
    }

    function test_addModuleImplementation_emit_NewModuleImplementation() public {
        bytes32 moduleType = mockModule.moduleType();
        uint256 moduleVersion = mockModule.version();

        vm.expectEmit(true, false, false, true);
        emit NewModuleImplementation(moduleType, moduleVersion, address(mockModule));

        vm.prank(factoryDeployer);
        twFactory.addModuleImplementation(moduleType, address(mockModule));
    }

    /// @dev Test `approveImplementation`

    function test_approveImplementation() public {
        assertTrue(twFactory.implementationApproval(address(mockModule)) == false);
        assertTrue(twFactory.currentModuleVersion(mockModule.moduleType()) == 0);

        vm.prank(factoryDeployer);
        twFactory.approveImplementation(address(mockModule), true);

        assertTrue(twFactory.implementationApproval(address(mockModule)));
        assertTrue(twFactory.currentModuleVersion(mockModule.moduleType()) == 0);
    }

    function test_approveImplementation_revert_invalidCaller() public {
        vm.expectRevert("not admin.");

        vm.prank(moduleDeployer);
        twFactory.approveImplementation(address(mockModule), true);
    }

    function test_approveImplementation_emit_ImplementationApproved() public {
        vm.expectEmit(false, false, false, true);
        emit ImplementationApproved(address(mockModule), true);

        vm.prank(factoryDeployer);
        twFactory.approveImplementation(address(mockModule), true);
    }

    /// @dev Test `deployProxyByImplementation`

    function _setUp_deployProxyByImplementation() internal {
        vm.prank(factoryDeployer);
        twFactory.approveImplementation(address(mockModule), true);
    }

    function test_deployProxyByImplementation(bytes32 _salt) public {
        _setUp_deployProxyByImplementation();

        bytes memory proxyBytecode = abi.encodePacked(type(TWProxy).creationCode, abi.encode(address(mockModule), ""));

        address computedProxyAddr = Create2.computeAddress(_salt, keccak256(proxyBytecode), address(twFactory));

        vm.prank(moduleDeployer);
        twFactory.deployProxyByImplementation(address(mockModule), "", _salt);

        assertEq(mockModule.moduleType(), MockThirdwebModule(computedProxyAddr).moduleType());
    }

    function test_deployProxyByImplementation_revert_invalidImpl() public {
        vm.expectRevert("implementation not approved");

        vm.prank(moduleDeployer);
        twFactory.deployProxyByImplementation(address(mockModule), "", "");
    }

    function test_deployProxyByImplementation_emit_ProxyDeployed() public {
        _setUp_deployProxyByImplementation();

        bytes32 salt = bytes32("Random");
        bytes memory proxyBytecode = abi.encodePacked(type(TWProxy).creationCode, abi.encode(address(mockModule), ""));
        address computedProxyAddr = Create2.computeAddress(salt, keccak256(proxyBytecode), address(twFactory));

        vm.expectEmit(true, true, false, true);
        emit ProxyDeployed(address(mockModule), computedProxyAddr, moduleDeployer);

        vm.prank(moduleDeployer);
        twFactory.deployProxyByImplementation(address(mockModule), "", salt);
    }

    /// @dev Test `deployProxyDeterministic`

    function _setUp_deployProxyDeterministic() internal {
        bytes32 moduleType = mockModule.moduleType();

        vm.prank(factoryDeployer);
        twFactory.addModuleImplementation(moduleType, address(mockModule));
    }

    function test_deployProxyDeterministic(bytes32 _salt) public {
        _setUp_deployProxyDeterministic();

        bytes32 moduleType = mockModule.moduleType();

        bytes memory proxyBytecode = abi.encodePacked(type(TWProxy).creationCode, abi.encode(address(mockModule), ""));
        address computedProxyAddr = Create2.computeAddress(_salt, keccak256(proxyBytecode), address(twFactory));

        vm.prank(moduleDeployer);
        twFactory.deployProxyDeterministic(moduleType, "", _salt);

        assertEq(mockModule.moduleType(), MockThirdwebModule(computedProxyAddr).moduleType());
    }

    function test_deployProxyDeterministic_revert_invalidImpl(bytes32 _salt) public {
        bytes32 moduleType = mockModule.moduleType();

        vm.expectRevert("implementation not approved");

        vm.prank(moduleDeployer);
        twFactory.deployProxyDeterministic(moduleType, "", _salt);
    }

    function test_deployProxyDeterministic_emit_ProxyDeployed() public {
        _setUp_deployProxyDeterministic();

        bytes32 moduleType = mockModule.moduleType();

        bytes32 salt = bytes32("Random");
        bytes memory proxyBytecode = abi.encodePacked(type(TWProxy).creationCode, abi.encode(address(mockModule), ""));
        address computedProxyAddr = Create2.computeAddress(salt, keccak256(proxyBytecode), address(twFactory));

        vm.expectEmit(true, true, false, true);
        emit ProxyDeployed(address(mockModule), computedProxyAddr, moduleDeployer);

        vm.prank(moduleDeployer);
        twFactory.deployProxyDeterministic(moduleType, "", salt);
    }

    /// @dev Test `deployProxy`

    function _setUp_deployProxy() internal {
        bytes32 moduleType = mockModule.moduleType();

        vm.prank(factoryDeployer);
        twFactory.addModuleImplementation(moduleType, address(mockModule));
    }

    function test_deployProxy() public {
        _setUp_deployProxy();

        bytes32 moduleType = mockModule.moduleType();

        vm.prank(moduleDeployer);
        address proxyAddr = twFactory.deployProxy(moduleType, "");

        assertEq(mockModule.moduleType(), MockThirdwebModule(proxyAddr).moduleType());
    }

    function test_deployProxy_sameBlock() public {
        _setUp_deployProxy();

        bytes32 moduleType = mockModule.moduleType();

        vm.startPrank(moduleDeployer);
        address proxyAddr = twFactory.deployProxy(moduleType, "");
        address proxyAddr2 = twFactory.deployProxy(moduleType, "");

        assertTrue(proxyAddr != proxyAddr2);
        assertEq(mockModule.moduleType(), MockThirdwebModule(proxyAddr).moduleType());
    }

    function test_deployProxy_revert_invalidImpl() public {
        bytes32 moduleType = mockModule.moduleType();

        vm.expectRevert("implementation not approved");

        vm.prank(moduleDeployer);
        twFactory.deployProxy(moduleType, "");
    }

    function test_deployProxy_emit_ProxyDeployed() public {
        _setUp_deployProxy();

        bytes32 moduleType = mockModule.moduleType();

        bytes32 salt = keccak256(abi.encodePacked(moduleType, block.number));
        bytes memory proxyBytecode = abi.encodePacked(type(TWProxy).creationCode, abi.encode(address(mockModule), ""));
        address computedProxyAddr = Create2.computeAddress(salt, keccak256(proxyBytecode), address(twFactory));

        vm.expectEmit(true, true, false, true);
        emit ProxyDeployed(address(mockModule), computedProxyAddr, moduleDeployer);

        vm.prank(moduleDeployer);
        twFactory.deployProxy(moduleType, "");
    }

    /**
     *      =====   Attack vectors   =====
     *
     *  - No proxy should be able to point to an unapproved implementation.
     *  - No non-admin should be able to approve an implementation.
     **/

    function testNoUnapprovedImpl(address _implementation) public {
        vm.prank(factoryDeployer);
        twFactory.approveImplementation(address(mockModule), true);

        if (_implementation != address(mockModule)) {
            vm.expectRevert("implementation not approved");

            vm.prank(moduleDeployer);
            twFactory.deployProxyByImplementation(_implementation, "", "");
        }
    }

    function testNoNonAdmin(address _implementation, address _deployer) public {
        bool toApprove = true;

        if (!twFactory.hasRole(twFactory.FACTORY_ROLE(), _deployer)) {
            vm.expectRevert("not admin.");

            vm.prank(_deployer);
            twFactory.approveImplementation(_implementation, toApprove);
        }
    }
}
