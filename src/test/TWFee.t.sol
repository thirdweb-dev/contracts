// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test imports
import "./utils/BaseTest.sol";
import "contracts/TWFee.sol";

// Helpers
import "contracts/interfaces/IThirdwebModule.sol";

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

interface ITWFeeData {
    event FeeInfoForModuleInstance(address indexed moduleInstance, TWFee.FeeInfo feeInfo);
    event FeeInfoForModuleType(bytes32 indexed moduleType, TWFee.FeeInfo feeInfo);
    event DefaultFeeInfo(TWFee.FeeType feeType, TWFee.FeeInfo feeInfo);
}

contract TWFeeTest is ITWFeeData, BaseTest {
    // Target contract
    TWFee internal twFee;

    // Helper contracts
    MockThirdwebModule internal mockModule;

    // Actors
    address internal moduleAdmin = address(0x1);
    address internal feeAdmin = address(0x2);
    address internal notFeeAdmin = address(0x3);

    // Test params
    address internal trustedForwarder = address(0x4);
    address internal defaultRoyaltyFeeRecipient = address(0x5);
    address internal defaultPlatformFeeRecipient = address(0x6);
    uint128 internal defaultRoyaltyFeeBps = 100;
    uint128 internal defaultPlatformFeeBps = 100;

    //  =====   Set up  =====

    function setUp() public {
        vm.prank(moduleAdmin);
        twFee = new TWFee(
            trustedForwarder,
            defaultRoyaltyFeeRecipient,
            defaultPlatformFeeRecipient,
            defaultRoyaltyFeeBps,
            defaultPlatformFeeBps
        );

        mockModule = new MockThirdwebModule();
    }

    //  =====   Initial state   =====

    /**
     *  @dev Tests the relevant initial state of the contract.
     *
     *  - Deployer of the contract has `DEFAULT_ADMIN_ROLE`
     *  - Deployer of the contract has `FEE_ROLE`
     */
    function test_initalState() public {
        bytes32 defaultAdminRole = twFee.DEFAULT_ADMIN_ROLE();
        bytes32 feeRole = twFee.FEE_ROLE();

        assertTrue(twFee.hasRole(defaultAdminRole, moduleAdmin));
        assertTrue(twFee.hasRole(feeRole, moduleAdmin));

        vm.prank(moduleAdmin);
        twFee.grantRole(feeRole, feeAdmin);
        assertTrue(twFee.hasRole(feeRole, feeAdmin));

        (address royaltyFeeRecipient, uint256 royaltyFeeBps) = twFee.getFeeInfo(
            address(mockModule),
            TWFee.FeeType.Royalty
        );
        assertEq(defaultRoyaltyFeeBps, royaltyFeeBps);
        assertEq(defaultRoyaltyFeeRecipient, royaltyFeeRecipient);

        (address platformFeeRecipient, uint256 platformFeeBps) = twFee.getFeeInfo(
            address(mockModule),
            TWFee.FeeType.Transaction
        );
        assertEq(defaultPlatformFeeBps, platformFeeBps);
        assertEq(defaultPlatformFeeRecipient, platformFeeRecipient);
    }

    function testFail() public {
        bytes32 feeRole = twFee.FEE_ROLE();

        vm.prank(moduleAdmin);
        twFee.grantRole(feeRole, feeAdmin);
        assertTrue(twFee.hasRole(feeRole, feeAdmin));

        vm.prank(feeAdmin);
        twFee.grantRole(feeRole, notFeeAdmin);
    }

    //  =====   Functionality tests   =====

    /// @dev Test `setDefaultFeeInfo`

    function test_setDefaultFeeInfo() public {
        address newDefaultFeeRecipient = address(0x123);
        uint256 newDefaultFeeBps = 50;

        vm.prank(moduleAdmin);
        twFee.setDefaultFeeInfo(newDefaultFeeBps, newDefaultFeeRecipient, TWFee.FeeType.Royalty);

        (address feeRecipient, uint256 feeBps) = twFee.getFeeInfo(address(mockModule), TWFee.FeeType.Royalty);
        assertEq(feeBps, newDefaultFeeBps);
        assertEq(feeRecipient, newDefaultFeeRecipient);

        vm.prank(moduleAdmin);
        twFee.setDefaultFeeInfo(newDefaultFeeBps, newDefaultFeeRecipient, TWFee.FeeType.Transaction);

        (feeRecipient, feeBps) = twFee.getFeeInfo(address(mockModule), TWFee.FeeType.Transaction);
        assertEq(feeBps, newDefaultFeeBps);
        assertEq(feeRecipient, newDefaultFeeRecipient);
    }

    function test_setDefaultFeeInfo_revert_notModuleAdmin() public {
        assertTrue(!twFee.hasRole(twFee.DEFAULT_ADMIN_ROLE(), feeAdmin));

        address newDefaultFeeRecipient = address(0x123);
        uint256 newDefaultFeeBps = 50;

        vm.expectRevert("not module admin.");
        vm.prank(feeAdmin);
        twFee.setDefaultFeeInfo(newDefaultFeeBps, newDefaultFeeRecipient, TWFee.FeeType.Royalty);
    }

    function test_setDefaultFeeInfo_revert_feeTooHigh() public {
        address newDefaultFeeRecipient = address(0x123);
        uint256 newDefaultFeeBps = 101;

        assertTrue(twFee.MAX_FEE_BPS() < newDefaultFeeBps);

        vm.expectRevert("fee too high.");
        vm.prank(moduleAdmin);
        twFee.setDefaultFeeInfo(newDefaultFeeBps, newDefaultFeeRecipient, TWFee.FeeType.Royalty);
    }

    function test_setDefaultFeeInfo_emit_DefaultFeeInfo() public {
        address newDefaultFeeRecipient = address(0x123);
        uint256 newDefaultFeeBps = 50;
        TWFee.FeeInfo memory feeInfo = TWFee.FeeInfo({ bps: newDefaultFeeBps, recipient: newDefaultFeeRecipient });

        vm.expectEmit(false, false, false, true);
        emit DefaultFeeInfo(TWFee.FeeType.Royalty, feeInfo);

        vm.prank(moduleAdmin);
        twFee.setDefaultFeeInfo(newDefaultFeeBps, newDefaultFeeRecipient, TWFee.FeeType.Royalty);
    }

    /// @dev Test `setFeeInfoForModuleType`

    function _setup_setFeeInfoForModuleType() public {
        bytes32 feeRole = twFee.FEE_ROLE();

        vm.prank(moduleAdmin);
        twFee.grantRole(feeRole, feeAdmin);
        assertTrue(twFee.hasRole(feeRole, feeAdmin));
    }

    function test_setFeeInfoForModuleType() public {
        _setup_setFeeInfoForModuleType();

        bytes32 moduleType = mockModule.moduleType();

        address feeRecipient = address(0x123);
        uint256 feeBps = 50;
        TWFee.FeeType feeType = TWFee.FeeType.Royalty;

        (uint256 bps, address recipient) = twFee.feeInfoByModuleType(moduleType, feeType);
        assertEq(recipient, address(0));
        assertEq(bps, 0);

        vm.prank(feeAdmin);
        twFee.setFeeInfoForModuleType(moduleType, feeBps, feeRecipient, feeType);

        (bps, recipient) = twFee.feeInfoByModuleType(moduleType, feeType);
        assertEq(recipient, feeRecipient);
        assertEq(bps, feeBps);
    }

    function test_setFeeInfoForModuleType_revert_notFeeAdmin() public {
        _setup_setFeeInfoForModuleType();

        bytes32 moduleType = mockModule.moduleType();

        address feeRecipient = address(0x123);
        uint256 feeBps = 50;
        TWFee.FeeType feeType = TWFee.FeeType.Royalty;

        vm.expectRevert("not fee admin.");

        vm.prank(notFeeAdmin);
        twFee.setFeeInfoForModuleType(moduleType, feeBps, feeRecipient, feeType);
    }

    function test_setFeeInfoForModuleType_revert_feeTooHigh() public {
        _setup_setFeeInfoForModuleType();

        bytes32 moduleType = mockModule.moduleType();

        address feeRecipient = address(0x123);
        uint256 feeBps = 101;
        TWFee.FeeType feeType = TWFee.FeeType.Royalty;

        vm.expectRevert("fee too high.");

        vm.prank(feeAdmin);
        twFee.setFeeInfoForModuleType(moduleType, feeBps, feeRecipient, feeType);
    }

    function test_setFeeInfoForModuleType_emit_FeeInfoForModuleType() public {
        _setup_setFeeInfoForModuleType();

        bytes32 moduleType = mockModule.moduleType();

        address feeRecipient = address(0x123);
        uint256 feeBps = 50;
        TWFee.FeeType feeType = TWFee.FeeType.Royalty;

        vm.expectEmit(true, false, false, true);
        emit FeeInfoForModuleType(moduleType, TWFee.FeeInfo({ bps: feeBps, recipient: feeRecipient }));

        vm.prank(feeAdmin);
        twFee.setFeeInfoForModuleType(moduleType, feeBps, feeRecipient, feeType);
    }

    /// @dev Test `setFeeInfoForModuleInstance`

    function _setup_setFeeInfoForModuleInstance() public {
        bytes32 feeRole = twFee.FEE_ROLE();

        vm.prank(moduleAdmin);
        twFee.grantRole(feeRole, feeAdmin);
        assertTrue(twFee.hasRole(feeRole, feeAdmin));
    }

    function test_setFeeInfoForModuleInstance() public {
        _setup_setFeeInfoForModuleInstance();

        address feeRecipient = address(0x123);
        uint256 feeBps = 50;
        TWFee.FeeType feeType = TWFee.FeeType.Royalty;

        (uint256 bps, address recipient) = twFee.feeInfoByModuleInstance(address(mockModule), feeType);
        assertEq(recipient, address(0));
        assertEq(bps, 0);

        vm.prank(feeAdmin);
        twFee.setFeeInfoForModuleInstance(address(mockModule), feeBps, feeRecipient, feeType);

        (bps, recipient) = twFee.feeInfoByModuleInstance(address(mockModule), feeType);
        assertEq(recipient, feeRecipient);
        assertEq(bps, feeBps);
    }

    function test_setFeeInfoForModuleInstance_revert_notFeeAdmin() public {
        address feeRecipient = address(0x123);
        uint256 feeBps = 50;
        TWFee.FeeType feeType = TWFee.FeeType.Royalty;

        vm.expectRevert("not fee admin.");

        vm.prank(notFeeAdmin);
        twFee.setFeeInfoForModuleInstance(address(mockModule), feeBps, feeRecipient, feeType);
    }

    function test_setFeeInfoForModuleInstance_revert_feeTooHigh() public {
        _setup_setFeeInfoForModuleInstance();

        address feeRecipient = address(0x123);
        uint256 feeBps = 101;
        TWFee.FeeType feeType = TWFee.FeeType.Royalty;

        vm.expectRevert("fee too high.");

        vm.prank(feeAdmin);
        twFee.setFeeInfoForModuleInstance(address(mockModule), feeBps, feeRecipient, feeType);
    }

    function test_setFeeInfoForModuleType_emit_FeeInfoForModuleInstance() public {
        _setup_setFeeInfoForModuleInstance();

        address feeRecipient = address(0x123);
        uint256 feeBps = 50;
        TWFee.FeeType feeType = TWFee.FeeType.Royalty;

        vm.expectEmit(true, false, false, true);
        emit FeeInfoForModuleInstance(address(mockModule), TWFee.FeeInfo({ bps: feeBps, recipient: feeRecipient }));

        vm.prank(feeAdmin);
        twFee.setFeeInfoForModuleInstance(address(mockModule), feeBps, feeRecipient, feeType);
    }

    /// @dev Test `getFeeInfo`

    function _setup_getFeeInfo() public {
        bytes32 feeRole = twFee.FEE_ROLE();

        vm.prank(moduleAdmin);
        twFee.grantRole(feeRole, feeAdmin);
        assertTrue(twFee.hasRole(feeRole, feeAdmin));
    }

    function test_getFeeInfo() public {
        _setup_getFeeInfo();

        bytes32 moduleType = mockModule.moduleType();
        TWFee.FeeType feeType = TWFee.FeeType.Royalty;

        (address recipient, uint256 bps) = twFee.getFeeInfo(address(mockModule), feeType);
        assertEq(recipient, defaultRoyaltyFeeRecipient);
        assertEq(bps, defaultRoyaltyFeeBps);

        address feeRecipientForType = address(0x123);
        uint256 feeBpsForType = 50;

        vm.prank(feeAdmin);
        twFee.setFeeInfoForModuleType(moduleType, feeBpsForType, feeRecipientForType, feeType);

        (recipient, bps) = twFee.getFeeInfo(address(mockModule), feeType);
        assertEq(recipient, feeRecipientForType);
        assertEq(bps, feeBpsForType);

        address feeRecipientForInstance = address(0x1234);
        uint256 feeBpsForInstance = 80;

        vm.prank(feeAdmin);
        twFee.setFeeInfoForModuleInstance(address(mockModule), feeBpsForInstance, feeRecipientForInstance, feeType);

        (recipient, bps) = twFee.getFeeInfo(address(mockModule), feeType);
        assertEq(recipient, feeRecipientForInstance);
        assertEq(bps, feeBpsForInstance);
    }

    /**
     *      =====   Attack vectors   =====
     *
     *  - No fees should ever be set greater than 1%.
     *  - No fees for module type / instance should ever be set by non fee admin.
     *  - No default fee should ever be set by non module admin.
     **/

    function _setup() public {
        bytes32 feeRole = twFee.FEE_ROLE();

        vm.prank(moduleAdmin);
        twFee.grantRole(feeRole, feeAdmin);
        assertTrue(twFee.hasRole(feeRole, feeAdmin));
    }

    function test_fuzz_feeBpsDefault(uint256 _bps) public {
        address recipient = address(0x123);
        if (_bps > 100) {
            vm.expectRevert("fee too high.");
        }
        vm.prank(moduleAdmin);
        twFee.setDefaultFeeInfo(_bps, recipient, TWFee.FeeType.Transaction);
    }

    function test_fuzz_feeBpsForModuleType(uint256 _bps) public {
        _setup();

        address recipient = address(0x123);
        bytes32 moduleType = mockModule.moduleType();

        if (_bps > 100) {
            vm.expectRevert("fee too high.");
        }
        vm.prank(feeAdmin);
        twFee.setFeeInfoForModuleType(moduleType, _bps, recipient, TWFee.FeeType.Transaction);
    }

    function test_fuzz_feeBpsForModuleInstance(uint256 _bps) public {
        _setup();

        address recipient = address(0x123);

        if (_bps > 100) {
            vm.expectRevert("fee too high.");
        }
        vm.prank(feeAdmin);
        twFee.setFeeInfoForModuleInstance(address(mockModule), _bps, recipient, TWFee.FeeType.Transaction);
    }

    function test_fuzz_setFeeForModuleType_invalidCaller(address _caller) public {
        _setup();

        address recipient = address(0x123);
        uint256 bps = 50;
        bytes32 moduleType = mockModule.moduleType();

        if (!twFee.hasRole(twFee.FEE_ROLE(), _caller)) {
            vm.expectRevert("not fee admin.");
        }
        vm.prank(_caller);
        twFee.setFeeInfoForModuleType(moduleType, bps, recipient, TWFee.FeeType.Transaction);
    }

    function test_fuzz_setFeeForModuleInstance_invalidCaller(address _caller) public {
        _setup();

        address recipient = address(0x123);
        uint256 bps = 50;

        if (!twFee.hasRole(twFee.FEE_ROLE(), _caller)) {
            vm.expectRevert("not fee admin.");
        }
        vm.prank(_caller);
        twFee.setFeeInfoForModuleInstance(address(mockModule), bps, recipient, TWFee.FeeType.Transaction);
    }

    function test_fuzz_feeBpsDefault(address _caller) public {
        address recipient = address(0x123);
        uint256 bps = 50;

        if (!twFee.hasRole(twFee.DEFAULT_ADMIN_ROLE(), _caller)) {
            vm.expectRevert("not module admin.");
        }
        vm.prank(_caller);
        twFee.setDefaultFeeInfo(bps, recipient, TWFee.FeeType.Transaction);
    }
}
