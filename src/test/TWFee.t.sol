// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test imports
import "./utils/BaseTest.sol";
import "contracts/TWFee.sol";

// Helpers
import "contracts/interfaces/IThirdwebModule.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "contracts/TWRegistry.sol";
import "contracts/TWFactory.sol";
import "contracts/TWProxy.sol";

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
    MockThirdwebModule internal mockModule;

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

        twFee = new TWFee(trustedForwarder, address(twRegistry), thirdwebTreasury);

        MockThirdwebModule mockModuleImpl = new MockThirdwebModule();
        twFactory.approveImplementation(address(mockModuleImpl), true);
        vm.stopPrank();

        bytes32 salt = bytes32("salt");
        bytes memory proxyBytecode = abi.encodePacked(type(TWProxy).creationCode, abi.encode(address(mockModule), ""));
        address computedProxyAddr = Create2.computeAddress(salt, keccak256(proxyBytecode), address(twFactory));

        vm.prank(mockModuleDeployer);
        twFactory.deployProxyByImplementation(address(mockModuleImpl), "", salt);

        mockModule = MockThirdwebModule(computedProxyAddr);
    }

    //  =====   Initial state   =====

    /**
     *  @dev Tests the relevant initial state of the contract.
     *
     *  - Deployer of the contract has `DEFAULT_ADMIN_ROLE`
     *  - Deployer of the contract has `FEE_ROLE`
     */
    function test_initalState(uint256 _feeType) public {
        assertEq(twRegistry.deployer(address(mockModule)), mockModuleDeployer);

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

    /// @dev Test `setPricingTierInfo`

    function test_setPricingTierInfo() public {
        uint256 durationForTier = 30 days;
        uint256 subscriptionAmount = 1 ether;
        address currencyForTier = NATIVE_TOKEN;

        vm.prank(moduleAdmin);
        twFee.setPricingTierInfo(
            uint256(ExampleFeeTier.Basic),
            durationForTier,
            currencyForTier,
            subscriptionAmount,
            true
        );

        assertTrue(twFee.isCurrencyApproved(uint256(ExampleFeeTier.Basic), currencyForTier));
        assertEq(twFee.priceToPayForCurrency(uint256(ExampleFeeTier.Basic), currencyForTier), subscriptionAmount);
        assertEq(twFee.tierDuration(uint256(ExampleFeeTier.Basic)), durationForTier);
    }

    function test_setPricingTierInfo_revert_notModuleAdmin() public {
        uint256 durationForTier = 30 days;
        uint256 subscriptionAmount = 1 ether;
        address currencyForTier = NATIVE_TOKEN;

        assertTrue(!twFee.hasRole(twFee.DEFAULT_ADMIN_ROLE(), feeAdmin));

        vm.expectRevert("not module admin.");

        vm.prank(feeAdmin);
        twFee.setPricingTierInfo(
            uint256(ExampleFeeTier.Basic),
            durationForTier,
            currencyForTier,
            subscriptionAmount,
            true
        );
    }

    function test_setPricingTierInfo_emit_PricingTierInfo() public {
        uint256 durationForTier = 30 days;
        uint256 subscriptionAmount = 1 ether;
        address currencyForTier = NATIVE_TOKEN;

        vm.expectEmit(true, true, false, true);
        emit PricingTierInfo(uint256(ExampleFeeTier.Basic), currencyForTier, true, durationForTier, subscriptionAmount);

        vm.prank(moduleAdmin);
        twFee.setPricingTierInfo(
            uint256(ExampleFeeTier.Basic),
            durationForTier,
            currencyForTier,
            subscriptionAmount,
            true
        );
    }

    /// @dev Test `selectSubscription`

    function _feeInfoForDefaultTier() internal returns (address, uint256) {
        return (address(0x123), 100);
    }

    function _feeInfoForUpgradedTier() internal returns (address, uint256) {
        return (address(0x12345), 50);
    }

    function _setup_selectSubscription() internal {
        _setup_setFeeInfoForTier();

        (address recipientForDefualtTier, uint256 bpsForDefaultTier) = _feeInfoForDefaultTier();
        (address recipientForUpgradedTier, uint256 bpsForUpgradedTier) = _feeInfoForUpgradedTier();

        vm.prank(feeAdmin);
        twFee.setFeeInfoForTier(
            uint256(ExampleFeeTier.Basic),
            bpsForDefaultTier,
            recipientForDefualtTier,
            uint256(FeeType.PrimarySale)
        );

        vm.prank(feeAdmin);
        twFee.setFeeInfoForTier(
            uint256(ExampleFeeTier.Growth),
            bpsForUpgradedTier,
            recipientForUpgradedTier,
            uint256(FeeType.PrimarySale)
        );

        uint256 durationForTier = 30 days;
        uint256 subscriptionAmount = 1 ether;
        address currencyForTier = NATIVE_TOKEN;

        vm.prank(moduleAdmin);
        twFee.setPricingTierInfo(
            uint256(ExampleFeeTier.Basic),
            durationForTier,
            currencyForTier,
            subscriptionAmount,
            true
        );
    }

    function test_selectSubscription() public {
        uint256 tier = uint256(ExampleFeeTier.Growth);
        uint256 subscriptionAmount = twFee.priceToPayForCurrency(tier, NATIVE_TOKEN);

        vm.deal(payer, subscriptionAmount);

        vm.prank(payer);
        twFee.selectSubscription(mockModuleDeployer, tier, subscriptionAmount, NATIVE_TOKEN);

        (address recipient, uint256 bps) = twFee.getFeeInfo(address(mockModule), uint256(FeeType.PrimarySale));
        (address recipientForTier, uint256 bpsForTier) = _feeInfoForUpgradedTier();

        assertEq(recipient, recipientForTier);
        assertEq(bps, bpsForTier);
    }

    /**
     *      =====   Attack vectors   =====
     *
     *  - No fees should ever be set greater than 1%.
     *  - No fees for module type / instance should ever be set by non fee admin.
     *  - No default fee should ever be set by non module admin.
     **/
}
