// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test imports
import "./utils/BaseTest.sol";
import "contracts/TWFactory.sol";

// Helpers
import "contracts/TWProxy.sol";
import "contracts/interfaces/IThirdwebModule.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./utils/Console.sol";

contract MockThirdwebModule is IThirdwebModule {
    string public contractURI;

    function moduleType() external view returns (bytes32) {
        return bytes32("MOCK");
    }

    function version() external view returns (uint256) {
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
    address internal moduleDeployer = address(0x2);

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
     *  - Deployer of the contract has `DEFAULT_ADMIN_ROLE`
     */
    function testInitialState() public {
        assertTrue(twFactory.hasRole(twFactory.DEFAULT_ADMIN_ROLE(), factoryDeployer));
    }

    //  =====   Functionality tests   =====

    /// @dev Test `addModuleImplementation`

    function testValidAddModule() public {
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

    function testAddModuleInvalidCaller() public {
        bytes32 moduleType = mockModule.moduleType();

        vm.expectRevert("not admin.");

        vm.prank(moduleDeployer);
        twFactory.addModuleImplementation(moduleType, address(mockModule));
    }

    function testAddModuleInvalidModuleType() public {
        bytes32 moduleType = bytes32("Random");

        assertTrue(mockModule.moduleType() != moduleType);

        vm.expectRevert("invalid module type.");

        vm.prank(factoryDeployer);
        twFactory.addModuleImplementation(moduleType, address(mockModule));
    }

    function testAddModuleEvent() public {
        bytes32 moduleType = mockModule.moduleType();
        uint256 moduleVersion = mockModule.version();

        vm.expectEmit(true, false, false, true);
        emit NewModuleImplementation(moduleType, moduleVersion, address(mockModule));

        vm.prank(factoryDeployer);
        twFactory.addModuleImplementation(moduleType, address(mockModule));
    }

    /// @dev Test `approveImplementation`

    function testValidApproveImpl() public {
        assertTrue(twFactory.implementationApproval(address(mockModule)) == false);
        assertTrue(twFactory.currentModuleVersion(mockModule.moduleType()) == 0);

        vm.prank(factoryDeployer);
        twFactory.approveImplementation(address(mockModule), true);

        assertTrue(twFactory.implementationApproval(address(mockModule)));
        assertTrue(twFactory.currentModuleVersion(mockModule.moduleType()) == 0);
    }

    function testApproveImplInvalidCaller() public {
        vm.expectRevert("not admin.");

        vm.prank(moduleDeployer);
        twFactory.approveImplementation(address(mockModule), true);
    }

    function testApproveImplEvent() public {
        vm.expectEmit(false, false, false, true);
        emit ImplementationApproved(address(mockModule), true);

        vm.prank(factoryDeployer);
        twFactory.approveImplementation(address(mockModule), true);
    }

    /// @dev Test `deployProxyByImplementation`

    function _setUpTestDeployProxyByImpl() internal {
        vm.prank(factoryDeployer);
        twFactory.approveImplementation(address(mockModule), true);
    }

    function testValidDeployProxyByImpl(bytes32 _salt) public {
        _setUpTestDeployProxyByImpl();

        bytes memory proxyBytecode = abi.encodePacked(type(TWProxy).creationCode, abi.encode(address(mockModule), ""));

        address computedProxyAddr = Create2.computeAddress(_salt, keccak256(proxyBytecode), address(twFactory));

        vm.prank(moduleDeployer);
        twFactory.deployProxyByImplementation(address(mockModule), "", _salt);

        assertEq(mockModule.moduleType(), MockThirdwebModule(computedProxyAddr).moduleType());
    }
}
