// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Test imports
import "./utils/BaseTest.sol";
import "contracts/TWFactory.sol";
import "contracts/TWRegistry.sol";

// Helpers
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "contracts/TWProxy.sol";
import "./utils/Console.sol";
import "./mocks/MockThirdwebContract.sol";

interface ITWFactoryData {
    event ProxyDeployed(address indexed implementation, address proxy, address indexed deployer);
    event ImplementationAdded(address implementation, bytes32 indexed contractType, uint256 version);
    event ImplementationApproved(address implementation, bool isApproved);
}

contract TWFactoryTest is ITWFactoryData, BaseTest {
    // Target contract
    TWFactory internal _factory;

    // Actors
    address internal proxyDeployer;
    address internal proxyDeployer2;

    // Test params
    MockThirdwebContract internal mockModule;
    address internal mockUnapprovedImplementation = address(0x5);

    //  =====   Set up  =====

    function setUp() public override {
        super.setUp();

        _factory = TWFactory(factory);
        proxyDeployer = getActor(10);
        proxyDeployer2 = getActor(11);

        vm.prank(factoryAdmin);
        mockModule = new MockThirdwebContract();
    }

    //  =====   Initial state   =====

    /**
     *  @dev Tests the relevant initial state of the contract.
     *
     *  - Deployer of the contract has `FACTORY_ROLE`
     */
    function test_initialState() public {
        assertTrue(_factory.hasRole(_factory.FACTORY_ROLE(), factoryAdmin));
    }

    //  =====   Functionality tests   =====

    /// @dev Test `addImplementation`

    function test_addImplementation() public {
        bytes32 contractType = mockModule.contractType();
        uint256 moduleVersion = mockModule.contractVersion();
        uint256 moduleVersionOnFactory = _factory.currentVersion(contractType);

        vm.prank(factoryAdmin);
        _factory.addImplementation(address(mockModule));

        assertTrue(_factory.approval(address(mockModule)));
        assertEq(address(mockModule), _factory.implementation(contractType, moduleVersion));
        assertEq(_factory.currentVersion(contractType), moduleVersionOnFactory + 1);
        assertEq(_factory.getImplementation(contractType, moduleVersion), address(mockModule));
    }

    function test_addImplementation_newImpl() public {
        vm.prank(factoryAdmin);
        _factory.addImplementation(address(mockModule));

        MockThirdwebContractV2 mockModuleV2 = new MockThirdwebContractV2();

        bytes32 contractType = mockModuleV2.contractType();
        uint256 moduleVersion = mockModuleV2.contractVersion();
        uint256 moduleVersionOnFactory = _factory.currentVersion(contractType);

        vm.prank(factoryAdmin);
        _factory.addImplementation(address(mockModuleV2));

        assertTrue(_factory.approval(address(mockModuleV2)));
        assertEq(address(mockModuleV2), _factory.implementation(contractType, moduleVersion));
        assertEq(_factory.currentVersion(contractType), moduleVersionOnFactory + 1);
        assertEq(_factory.getImplementation(contractType, moduleVersion), address(mockModuleV2));
    }

    function test_addImplementation_revert_sameVersionForNewImpl() public {
        MockThirdwebContract mockModuleV2 = new MockThirdwebContract();

        vm.prank(factoryAdmin);
        _factory.addImplementation(address(mockModule));

        vm.expectRevert("wrong module version");

        vm.prank(factoryAdmin);
        _factory.addImplementation(address(mockModuleV2));
    }

    function test_addImplementation_revert_invalidCaller() public {
        vm.expectRevert("not admin.");

        vm.prank(proxyDeployer);
        _factory.addImplementation(address(mockModule));
    }

    function test_addImplementation_emit_ImplementationAdded() public {
        bytes32 contractType = mockModule.contractType();
        uint256 moduleVersion = mockModule.contractVersion();

        vm.expectEmit(true, false, false, true);
        emit ImplementationAdded(address(mockModule), contractType, moduleVersion);

        vm.prank(factoryAdmin);
        _factory.addImplementation(address(mockModule));
    }

    /// @dev Test `approveImplementation`

    function test_approveImplementation() public {
        assertTrue(_factory.approval(address(mockModule)) == false);
        assertTrue(_factory.currentVersion(mockModule.contractType()) == 0);

        vm.prank(factoryAdmin);
        _factory.approveImplementation(address(mockModule), true);

        assertTrue(_factory.approval(address(mockModule)));
        assertTrue(_factory.currentVersion(mockModule.contractType()) == 0);
    }

    function test_approveImplementation_revert_invalidCaller() public {
        vm.expectRevert("not admin.");

        vm.prank(proxyDeployer);
        _factory.approveImplementation(address(mockModule), true);
    }

    function test_approveImplementation_emit_ImplementationApproved() public {
        vm.expectEmit(false, false, false, true);
        emit ImplementationApproved(address(mockModule), true);

        vm.prank(factoryAdmin);
        _factory.approveImplementation(address(mockModule), true);
    }

    /// @dev Test `deployProxyByImplementation`

    function setUp_deployProxyByImplementation() internal {
        vm.prank(factoryAdmin);
        _factory.approveImplementation(address(mockModule), true);
    }

    function test_deployProxyByImplementation(bytes32 _salt) public {
        setUp_deployProxyByImplementation();

        address computedProxyAddr = Clones.predictDeterministicAddress(
            address(mockModule),
            keccak256(abi.encodePacked(proxyDeployer, _salt)),
            factory
        );

        vm.prank(proxyDeployer);
        address deployedAddr = _factory.deployProxyByImplementation(address(mockModule), "", _salt);

        assertEq(deployedAddr, computedProxyAddr);
        assertEq(mockModule.contractType(), MockThirdwebContract(computedProxyAddr).contractType());
    }

    function test_deployProxyByImplementation_revert_invalidImpl() public {
        vm.expectRevert("implementation not approved");

        vm.prank(proxyDeployer);
        _factory.deployProxyByImplementation(address(mockModule), "", "");
    }

    function test_deployProxyByImplementation_emit_ProxyDeployed() public {
        setUp_deployProxyByImplementation();

        bytes32 salt = bytes32("Random");
        address computedProxyAddr = Clones.predictDeterministicAddress(
            address(mockModule),
            keccak256(abi.encodePacked(proxyDeployer, salt)),
            factory
        );

        vm.expectEmit(true, true, false, true);
        emit ProxyDeployed(address(mockModule), computedProxyAddr, proxyDeployer);

        vm.prank(proxyDeployer);
        _factory.deployProxyByImplementation(address(mockModule), "", salt);
    }

    /// @dev Test `deployProxyDeterministic`

    function setUp_deployProxyDeterministic() internal {
        vm.prank(factoryAdmin);
        _factory.addImplementation(address(mockModule));
    }

    function test_deployProxyDeterministic(bytes32 _salt) public {
        setUp_deployProxyDeterministic();

        bytes32 contractType = mockModule.contractType();

        address computedProxyAddr = Clones.predictDeterministicAddress(
            address(mockModule),
            keccak256(abi.encodePacked(proxyDeployer, _salt)),
            factory
        );

        vm.prank(proxyDeployer);
        address proxyAddr = _factory.deployProxyDeterministic(contractType, "", _salt);

        assertEq(proxyAddr, computedProxyAddr);
        assertEq(mockModule.contractType(), MockThirdwebContract(computedProxyAddr).contractType());
    }

    function test_deployProxyDeterministic_revert_invalidImpl(bytes32 _salt) public {
        bytes32 contractType = mockModule.contractType();

        vm.expectRevert("implementation not approved");

        vm.prank(proxyDeployer);
        _factory.deployProxyDeterministic(contractType, "", _salt);
    }

    function test_deployProxyDeterministic_emit_ProxyDeployed() public {
        setUp_deployProxyDeterministic();

        bytes32 contractType = mockModule.contractType();

        bytes32 salt = bytes32("Random");
        bytes memory proxyBytecode = abi.encodePacked(type(TWProxy).creationCode, abi.encode(address(mockModule), ""));
        address computedProxyAddr = Create2.computeAddress(salt, keccak256(proxyBytecode), address(_factory));

        vm.expectEmit(true, true, false, true);
        emit ProxyDeployed(address(mockModule), computedProxyAddr, proxyDeployer);

        vm.prank(proxyDeployer);
        _factory.deployProxyDeterministic(contractType, "", salt);
    }

    /// @dev Test `deployProxy`

    function setUp_deployProxy() internal {
        vm.prank(factoryAdmin);
        _factory.addImplementation(address(mockModule));
    }

    function test_deployProxy() public {
        setUp_deployProxy();

        bytes32 contractType = mockModule.contractType();

        vm.prank(proxyDeployer);
        address proxyAddr = _factory.deployProxy(contractType, "");

        assertEq(mockModule.contractType(), MockThirdwebContract(proxyAddr).contractType());
    }

    function test_deployProxy_sameBlock() public {
        setUp_deployProxy();

        bytes32 contractType = mockModule.contractType();

        vm.startPrank(proxyDeployer);
        address proxyAddr = _factory.deployProxy(contractType, "");
        address proxyAddr2 = _factory.deployProxy(contractType, "");

        assertTrue(proxyAddr != proxyAddr2);
        assertEq(mockModule.contractType(), MockThirdwebContract(proxyAddr).contractType());
    }

    function test_deployProxy_revert_invalidImpl() public {
        bytes32 contractType = mockModule.contractType();

        vm.expectRevert("implementation not approved");

        vm.prank(proxyDeployer);
        _factory.deployProxy(contractType, "");
    }

    function test_deployProxy_emit_ProxyDeployed() public {
        setUp_deployProxy();

        bytes32 contractType = mockModule.contractType();

        bytes32 salt = keccak256(abi.encodePacked(contractType, block.number));
        bytes memory proxyBytecode = abi.encodePacked(type(TWProxy).creationCode, abi.encode(address(mockModule), ""));
        address computedProxyAddr = Create2.computeAddress(salt, keccak256(proxyBytecode), address(_factory));

        vm.expectEmit(true, true, false, true);
        emit ProxyDeployed(address(mockModule), computedProxyAddr, proxyDeployer);

        vm.prank(proxyDeployer);
        _factory.deployProxy(contractType, "");
    }

    /**
     *      =====   Attack vectors   =====
     *
     *  - No proxy should be able to point to an unapproved implementation.
     *  - No non-admin should be able to approve an implementation.
     **/

    function testNoUnapprovedImpl(address _implementation) public {
        vm.prank(factoryAdmin);
        _factory.approveImplementation(address(mockModule), true);

        if (_implementation != address(mockModule)) {
            vm.expectRevert("implementation not approved");

            vm.prank(proxyDeployer);
            _factory.deployProxyByImplementation(_implementation, "", "");
        }
    }

    function testNoNonAdmin(address _implementation, address _deployer) public {
        bool toApprove = true;

        if (!_factory.hasRole(_factory.FACTORY_ROLE(), _deployer)) {
            vm.expectRevert("not admin.");

            vm.prank(_deployer);
            _factory.approveImplementation(_implementation, toApprove);
        }
    }
}
