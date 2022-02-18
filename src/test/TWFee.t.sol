// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Test imports
import "./mocks/MockThirdwebContract.sol";
import "./utils/BaseTest.sol";
import "contracts/TWFee.sol";

// Helpers
import "@openzeppelin/contracts/utils/Create2.sol";
import "contracts/TWRegistry.sol";
import "contracts/TWFactory.sol";
import "contracts/TWProxy.sol";

interface ITWFeeData {
    enum ExampleFeeTier {
        Basic,
        Growth,
        Enterprise
    }

    enum FeeType {
        PrimarySale,
        Royalty,
        MarketSale,
        Splits
    }

    event TierForUser(
        address indexed user,
        uint256 indexed tier,
        address currencyForPayment,
        uint256 pricePaid,
        uint256 expirationTimestamp
    );
    event PricingTierInfo(
        uint256 indexed tier,
        address indexed currency,
        bool isCurrencyApproved,
        uint256 _duration,
        uint256 priceForCurrency
    );
    event FeeInfoForTier(uint256 indexed tier, uint256 indexed feeType, address recipient, uint256 bps);
    event NewTreasury(address oldTreasury, address newTreasury);
}

contract TWFeeTest is ITWFeeData, BaseTest {
    // Target contract
    TWFee internal twFee;

    // Helper contracts
    TWRegistry internal twRegistry;
    TWFactory internal twFactory;
    MockThirdwebContract internal mockModule;

    // Actors
    address internal mockModuleDeployer;
    address internal moduleAdmin = address(0x1);
    address internal feeAdmin = address(0x2);
    address internal notFeeAdmin = address(0x3);
    address internal payer = address(0x4);

    // Test params
    address internal trustedForwarder = address(0x4);
    address internal thirdwebTreasury = address(0x5);
    address internal constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    //  =====   Set up  =====

    function setUp() public {
        vm.startPrank(moduleAdmin);

        twFactory = new TWFactory(trustedForwarder);
        twRegistry = TWRegistry(twFactory.registry());

        twFee = new TWFee(trustedForwarder, address(twRegistry));

        MockThirdwebContract mockModuleImpl = new MockThirdwebContract();
        twFactory.approveImplementation(address(mockModuleImpl), true);
        vm.stopPrank();

        bytes32 salt = bytes32("salt");
        bytes memory proxyBytecode = abi.encodePacked(type(TWProxy).creationCode, abi.encode(address(mockModule), ""));
        address computedProxyAddr = Create2.computeAddress(salt, keccak256(proxyBytecode), address(twFactory));

        vm.prank(mockModuleDeployer);
        twFactory.deployProxyByImplementation(address(mockModuleImpl), "", salt);

        mockModule = MockThirdwebContract(computedProxyAddr);
    }

    //  =====   Initial state   =====

    /**
     *  @dev Tests the relevant initial state of the contract.
     *
     *  - Deployer of the contract has `DEFAULT_ADMIN_ROLE`
     *  - Deployer of the contract has `FEE_ROLE`
     */
    function test_initalState(uint256 _feeType) public {
        assertEq(twFactory.deployer(address(mockModule)), mockModuleDeployer);

        bytes32 defaultAdminRole = twFee.DEFAULT_ADMIN_ROLE();
        bytes32 feeRole = twFee.FEE_ROLE();

        assertTrue(twFee.hasRole(defaultAdminRole, moduleAdmin));
        assertTrue(twFee.hasRole(feeRole, moduleAdmin));

        vm.prank(moduleAdmin);
        twFee.grantRole(feeRole, feeAdmin);
        assertTrue(twFee.hasRole(feeRole, feeAdmin));

        // For any fee type
        (address recipient, uint256 bps) = twFee.getFeeInfo(address(mockModule), _feeType);
        assertTrue(recipient == address(0) && bps == 0);
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

    function _setup_setFeeInfoForTier() internal {
        bytes32 feeRole = twFee.FEE_ROLE();

        vm.prank(moduleAdmin);
        twFee.grantRole(feeRole, feeAdmin);
    }

    /// @dev Test `setFeeInfoForTier`

    function test_setFeeInfoForTier() public {
        _setup_setFeeInfoForTier();

        address recipientForTier = address(0x123);
        uint256 bpsForTier = 100;

        vm.prank(feeAdmin);
        twFee.setFeeInfoForTier(
            uint256(ExampleFeeTier.Basic),
            bpsForTier,
            recipientForTier,
            uint256(FeeType.PrimarySale)
        );

        (address recipient, uint256 bps) = twFee.getFeeInfo(address(mockModule), uint256(FeeType.PrimarySale));
        assertTrue(recipient == recipientForTier && bps == bpsForTier);
    }

    function test_setFeeInfoForTier_revert_notFeeAdmin() public {
        _setup_setFeeInfoForTier();

        address recipientForTier = address(0x123);
        uint256 bpsForTier = 100;

        vm.expectRevert("not fee admin.");

        vm.prank(notFeeAdmin);
        twFee.setFeeInfoForTier(
            uint256(ExampleFeeTier.Basic),
            bpsForTier,
            recipientForTier,
            uint256(FeeType.PrimarySale)
        );
    }

    function test_setFeeInfoForTier_revert_invalidFeeBps() public {
        _setup_setFeeInfoForTier();

        address recipientForTier = address(0x123);
        uint256 bpsForTier = 101;

        vm.expectRevert("fee too high.");

        vm.prank(feeAdmin);
        twFee.setFeeInfoForTier(
            uint256(ExampleFeeTier.Basic),
            bpsForTier,
            recipientForTier,
            uint256(FeeType.PrimarySale)
        );
    }

    function test_setFeeInfoForTier_emit_FeeInfoForTier() public {
        _setup_setFeeInfoForTier();

        address recipientForTier = address(0x123);
        uint256 bpsForTier = 100;

        vm.expectEmit(true, true, false, true);
        emit FeeInfoForTier(uint256(ExampleFeeTier.Basic), uint256(FeeType.PrimarySale), recipientForTier, bpsForTier);

        vm.prank(feeAdmin);
        twFee.setFeeInfoForTier(
            uint256(ExampleFeeTier.Basic),
            bpsForTier,
            recipientForTier,
            uint256(FeeType.PrimarySale)
        );
    }

    /**
     *      =====   Attack vectors   =====
     *
     *  - No fees should ever be set greater than 1%.
     *  - No fees for module type / instance should ever be set by non fee admin.
     *  - No default fee should ever be set by non module admin.
     **/
}
