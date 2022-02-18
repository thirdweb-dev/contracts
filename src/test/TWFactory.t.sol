// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Test imports
import "./utils/BaseTest.sol";
import "contracts/TWFactory.sol";
import "contracts/TWRegistry.sol";

// Helpers
import "contracts/TWProxy.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./utils/Console.sol";
import "./mocks/MockThirdwebContract.sol";

interface ITWFactoryData {
    event ProxyDeployed(address indexed implementation, address proxy, address indexed deployer);
    event NewModuleImplementation(bytes32 indexed contractType, uint256 version, address implementation);
    event ImplementationApproved(address implementation, bool isApproved);
}

contract TWFactoryTest is ITWFactoryData, BaseTest {
    // Target contract
    TWFactory internal twFactory;

    // Secondary contracts
    MockThirdwebContract internal mockModule;

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
        mockModule = new MockThirdwebContract();
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

    /// @dev Test `addImplementation`

    function test_addImplementation() public {
        bytes32 contractType = mockModule.contractType();
        uint256 moduleVersion = mockModule.contractVersion();
        uint256 moduleVersionOnFactory = twFactory.currentVersion(contractType);

        vm.prank(factoryDeployer);
        twFactory.addImplementation(address(mockModule));

        assertTrue(twFactory.approval(address(mockModule)));
        assertEq(address(mockModule), twFactory.implementation(contractType, moduleVersion));
        assertEq(twFactory.currentVersion(contractType), moduleVersionOnFactory + 1);
        assertEq(twFactory.getImplementation(contractType, moduleVersion), address(mockModule));
    }

    function test_addImplementation_revert_invalidCaller() public {
        bytes32 contractType = mockModule.contractType();

        vm.expectRevert("not admin.");

        vm.prank(moduleDeployer);
        twFactory.addImplementation(address(mockModule));
    }

    function test_addImplementation_emit_NewModuleImplementation() public {
        bytes32 contractType = mockModule.contractType();
        uint256 moduleVersion = mockModule.contractVersion();

        vm.expectEmit(true, false, false, true);
        emit NewModuleImplementation(contractType, moduleVersion, address(mockModule));

        vm.prank(factoryDeployer);
        twFactory.addImplementation(address(mockModule));
    }

    /// @dev Test `approveImplementation`

    function test_approveImplementation() public {
        assertTrue(twFactory.approval(address(mockModule)) == false);
        assertTrue(twFactory.currentVersion(mockModule.contractType()) == 0);

        vm.prank(factoryDeployer);
        twFactory.approveImplementation(address(mockModule), true);

        assertTrue(twFactory.approval(address(mockModule)));
        assertTrue(twFactory.currentVersion(mockModule.contractType()) == 0);
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

        assertEq(mockModule.contractType(), MockThirdwebContract(computedProxyAddr).contractType());
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
        bytes32 contractType = mockModule.contractType();

        vm.prank(factoryDeployer);
        twFactory.addImplementation(address(mockModule));
    }

    function test_deployProxyDeterministic(bytes32 _salt) public {
        _setUp_deployProxyDeterministic();

        bytes32 contractType = mockModule.contractType();

        bytes memory proxyBytecode = abi.encodePacked(type(TWProxy).creationCode, abi.encode(address(mockModule), ""));
        address computedProxyAddr = Create2.computeAddress(_salt, keccak256(proxyBytecode), address(twFactory));

        vm.prank(moduleDeployer);
        twFactory.deployProxyDeterministic(contractType, "", _salt);

        assertEq(mockModule.contractType(), MockThirdwebContract(computedProxyAddr).contractType());
    }

    function test_deployProxyDeterministic_revert_invalidImpl(bytes32 _salt) public {
        bytes32 contractType = mockModule.contractType();

        vm.expectRevert("implementation not approved");

        vm.prank(moduleDeployer);
        twFactory.deployProxyDeterministic(contractType, "", _salt);
    }

    function test_deployProxyDeterministic_emit_ProxyDeployed() public {
        _setUp_deployProxyDeterministic();

        bytes32 contractType = mockModule.contractType();

        bytes32 salt = bytes32("Random");
        bytes memory proxyBytecode = abi.encodePacked(type(TWProxy).creationCode, abi.encode(address(mockModule), ""));
        address computedProxyAddr = Create2.computeAddress(salt, keccak256(proxyBytecode), address(twFactory));

        vm.expectEmit(true, true, false, true);
        emit ProxyDeployed(address(mockModule), computedProxyAddr, moduleDeployer);

        vm.prank(moduleDeployer);
        twFactory.deployProxyDeterministic(contractType, "", salt);
    }

    /// @dev Test `deployProxy`

    function _setUp_deployProxy() internal {
        bytes32 contractType = mockModule.contractType();

        vm.prank(factoryDeployer);
        twFactory.addImplementation(address(mockModule));
    }

    function test_deployProxy() public {
        _setUp_deployProxy();

        bytes32 contractType = mockModule.contractType();

        vm.prank(moduleDeployer);
        address proxyAddr = twFactory.deployProxy(contractType, "");

        assertEq(mockModule.contractType(), MockThirdwebContract(proxyAddr).contractType());
    }

    function test_deployProxy_sameBlock() public {
        _setUp_deployProxy();

        bytes32 contractType = mockModule.contractType();

        vm.startPrank(moduleDeployer);
        address proxyAddr = twFactory.deployProxy(contractType, "");
        address proxyAddr2 = twFactory.deployProxy(contractType, "");

        assertTrue(proxyAddr != proxyAddr2);
        assertEq(mockModule.contractType(), MockThirdwebContract(proxyAddr).contractType());
    }

    function test_deployProxy_revert_invalidImpl() public {
        bytes32 contractType = mockModule.contractType();

        vm.expectRevert("implementation not approved");

        vm.prank(moduleDeployer);
        twFactory.deployProxy(contractType, "");
    }

    function test_deployProxy_emit_ProxyDeployed() public {
        _setUp_deployProxy();

        bytes32 contractType = mockModule.contractType();

        bytes32 salt = keccak256(abi.encodePacked(contractType, block.number));
        bytes memory proxyBytecode = abi.encodePacked(type(TWProxy).creationCode, abi.encode(address(mockModule), ""));
        address computedProxyAddr = Create2.computeAddress(salt, keccak256(proxyBytecode), address(twFactory));

        vm.expectEmit(true, true, false, true);
        emit ProxyDeployed(address(mockModule), computedProxyAddr, moduleDeployer);

        vm.prank(moduleDeployer);
        twFactory.deployProxy(contractType, "");
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
