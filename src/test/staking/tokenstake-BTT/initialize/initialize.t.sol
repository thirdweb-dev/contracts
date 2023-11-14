// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";
import { IStaking20 } from "contracts/extension/interface/IStaking20.sol";

contract TokenReturnZeroDecimals {
    function decimals() public pure returns (uint8) {
        return 0;
    }
}

contract TokenStakeTest_Initialize is BaseTest {
    address public implementation;
    address public proxy;

    address public stakingToken;
    address public rewardToken;

    uint256 public rewardRatioDenominator;
    uint80 public timeUnit;

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event ContractURIUpdated(string prevURI, string newURI);

    function setUp() public override {
        super.setUp();

        stakingToken = address(erc20Aux);
        rewardToken = address(erc20);

        rewardRatioDenominator = 50;
        timeUnit = 60;

        // Deploy implementation.
        implementation = address(new TokenStake(address(weth)));

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = address(
            new TWProxy(
                implementation,
                abi.encodeCall(
                    TokenStake.initialize,
                    (
                        deployer,
                        CONTRACT_URI,
                        forwarders(),
                        rewardToken,
                        stakingToken,
                        timeUnit,
                        3,
                        rewardRatioDenominator
                    )
                )
            )
        );
    }

    function test_initialize_initializingImplementation() public {
        vm.expectRevert("Initializable: contract is already initialized");
        TokenStake(payable(implementation)).initialize(
            deployer,
            CONTRACT_URI,
            forwarders(),
            rewardToken,
            stakingToken,
            timeUnit,
            3,
            rewardRatioDenominator
        );
    }

    modifier whenNotImplementation() {
        _;
    }

    function test_initialize_proxyAlreadyInitialized() public whenNotImplementation {
        vm.expectRevert("Initializable: contract is already initialized");
        TokenStake(payable(proxy)).initialize(
            deployer,
            CONTRACT_URI,
            forwarders(),
            rewardToken,
            stakingToken,
            timeUnit,
            3,
            rewardRatioDenominator
        );
    }

    modifier whenProxyNotInitialized() {
        proxy = address(new TWProxy(implementation, ""));
        _;
    }

    modifier whenRewardStakingTokenSame() {
        rewardToken = stakingToken;
        _;
    }

    function test_initialize_rewardTokenStakingTokenSame()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenRewardStakingTokenSame
    {
        vm.expectRevert("Reward Token and Staking Token can't be same.");
        TokenStake(payable(proxy)).initialize(
            deployer,
            CONTRACT_URI,
            forwarders(),
            rewardToken,
            stakingToken,
            timeUnit,
            3,
            rewardRatioDenominator
        );
    }

    modifier whenRewardStakingTokenNotSame() {
        _;
    }

    modifier whenStakingTokenZeroAddress() {
        stakingToken = address(0);
        _;
    }

    function test_initialize_stakingTokenZeroAddress()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenRewardStakingTokenNotSame
        whenStakingTokenZeroAddress
    {
        vm.expectRevert();
        TokenStake(payable(proxy)).initialize(
            deployer,
            CONTRACT_URI,
            forwarders(),
            rewardToken,
            stakingToken,
            timeUnit,
            3,
            rewardRatioDenominator
        );
    }

    modifier whenStakingTokenNotZeroAddress() {
        _;
    }

    modifier whenStakingDecimalsEqualZero() {
        stakingToken = address(new TokenReturnZeroDecimals());
        _;
    }

    function test_intialize_stakingDecimalsZero()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenRewardStakingTokenNotSame
        whenStakingTokenNotZeroAddress
        whenStakingDecimalsEqualZero
    {
        vm.expectRevert("decimals 0");
        TokenStake(payable(proxy)).initialize(
            deployer,
            CONTRACT_URI,
            forwarders(),
            rewardToken,
            stakingToken,
            timeUnit,
            3,
            rewardRatioDenominator
        );
    }

    modifier whenStakingDecimalsDoNotEqualZero() {
        _;
    }

    modifier whenRewardTokenDecimalsEqualZero() {
        rewardToken = address(new TokenReturnZeroDecimals());
        _;
    }

    function test_initialize_rewardTokenDecimalsEqualZero()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenRewardStakingTokenNotSame
        whenStakingTokenNotZeroAddress
        whenStakingDecimalsDoNotEqualZero
        whenRewardTokenDecimalsEqualZero
    {
        vm.expectRevert("decimals 0");
        TokenStake(payable(proxy)).initialize(
            deployer,
            CONTRACT_URI,
            forwarders(),
            rewardToken,
            stakingToken,
            timeUnit,
            3,
            rewardRatioDenominator
        );
    }

    modifier whenRewardTokenDecimalsNotEqualZero() {
        _;
    }

    modifier whenRewardRatioDenominatorEqualsZero() {
        rewardRatioDenominator = 0;
        _;
    }

    function test_initialize_rewardRatioDenominatorEqualsZero()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenRewardStakingTokenNotSame
        whenStakingTokenNotZeroAddress
        whenStakingDecimalsDoNotEqualZero
        whenRewardTokenDecimalsNotEqualZero
        whenRewardRatioDenominatorEqualsZero
    {
        vm.expectRevert("divide by 0");
        TokenStake(payable(proxy)).initialize(
            deployer,
            CONTRACT_URI,
            forwarders(),
            rewardToken,
            stakingToken,
            timeUnit,
            3,
            rewardRatioDenominator
        );
    }

    modifier whenRewardRatioDenominatorDoesNotEqualZero() {
        _;
    }

    modifier whenStakingTokenIsNativeToken() {
        stakingToken = NATIVE_TOKEN;
        _;
    }

    function test_initialize_stakingTokenNativeToken()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenRewardStakingTokenNotSame
        whenStakingTokenNotZeroAddress
        whenStakingDecimalsDoNotEqualZero
        whenRewardTokenDecimalsNotEqualZero
        whenStakingTokenIsNativeToken
    {
        TokenStake(payable(proxy)).initialize(
            deployer,
            CONTRACT_URI,
            forwarders(),
            rewardToken,
            stakingToken,
            timeUnit,
            3,
            rewardRatioDenominator
        );

        TokenStake stakingContract = TokenStake(payable(proxy));

        uint256 stakingTokenDecimals = stakingContract.stakingTokenDecimals();
        assertEq(stakingTokenDecimals, 18);
    }

    modifier whenStakingTokenIsNotNativeToken() {
        _;
    }

    modifier whenRewardTokenIsNativeToken() {
        rewardToken = NATIVE_TOKEN;
        _;
    }

    function test_initialize_rewardTokenNativeToken()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenRewardStakingTokenNotSame
        whenStakingTokenNotZeroAddress
        whenStakingDecimalsDoNotEqualZero
        whenRewardTokenDecimalsNotEqualZero
        whenStakingTokenIsNotNativeToken
        whenRewardTokenIsNativeToken
    {
        TokenStake(payable(proxy)).initialize(
            deployer,
            CONTRACT_URI,
            forwarders(),
            rewardToken,
            stakingToken,
            timeUnit,
            3,
            rewardRatioDenominator
        );

        TokenStake stakingContract = TokenStake(payable(proxy));

        uint256 rewardTokenDecimals = stakingContract.rewardTokenDecimals();
        assertEq(rewardTokenDecimals, 18);
    }

    modifier whenRewardTokenIsNotNativeToken() {
        _;
    }

    modifier whenTimeUnitEqualsZero() {
        timeUnit = 0;
        _;
    }

    function test_initialize_timeUnitEqualsZero()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenRewardStakingTokenNotSame
        whenStakingTokenNotZeroAddress
        whenStakingDecimalsDoNotEqualZero
        whenRewardTokenDecimalsNotEqualZero
        whenStakingTokenIsNotNativeToken
        whenRewardTokenIsNotNativeToken
        whenTimeUnitEqualsZero
    {
        vm.expectRevert("time-unit can't be 0");
        TokenStake(payable(proxy)).initialize(
            deployer,
            CONTRACT_URI,
            forwarders(),
            rewardToken,
            stakingToken,
            timeUnit,
            3,
            rewardRatioDenominator
        );
    }

    modifier whenTimeUnitDoesNotEqualZero() {
        _;
    }

    function test_initialize()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenRewardStakingTokenNotSame
        whenStakingTokenNotZeroAddress
        whenStakingDecimalsDoNotEqualZero
        whenRewardTokenDecimalsNotEqualZero
        whenStakingTokenIsNotNativeToken
        whenRewardTokenIsNotNativeToken
        whenTimeUnitDoesNotEqualZero
    {
        bytes32 _defaultAdminRole = bytes32(0x00);

        TokenStake(payable(proxy)).initialize(
            deployer,
            CONTRACT_URI,
            forwarders(),
            rewardToken,
            stakingToken,
            timeUnit,
            3,
            rewardRatioDenominator
        );

        TokenStake stakingContract = TokenStake(payable(proxy));

        address[] memory _trustedForwarders = forwarders();
        for (uint256 i = 0; i < _trustedForwarders.length; i++) {
            assertTrue(stakingContract.isTrustedForwarder(_trustedForwarders[i]));
        }

        assertEq(stakingContract.contractURI(), CONTRACT_URI);

        assertEq(stakingContract.rewardToken(), rewardToken);
        assertEq(stakingContract.stakingToken(), stakingToken);

        assertEq(ERC20(rewardToken).decimals(), stakingContract.rewardTokenDecimals());
        assertEq(ERC20(stakingToken).decimals(), stakingContract.stakingTokenDecimals());

        assertEq(stakingContract.getTimeUnit(), timeUnit);

        (uint256 numerator, uint256 denominator) = stakingContract.getRewardRatio();
        assertEq(numerator, 3);
        assertEq(denominator, rewardRatioDenominator);

        assertEq(stakingContract.hasRole(_defaultAdminRole, deployer), true);
    }

    function test_initialize_emitRoleGranted_DefaultAdmin()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenRewardStakingTokenNotSame
        whenStakingTokenNotZeroAddress
        whenStakingDecimalsDoNotEqualZero
        whenRewardTokenDecimalsNotEqualZero
        whenStakingTokenIsNotNativeToken
        whenRewardTokenIsNotNativeToken
        whenTimeUnitDoesNotEqualZero
    {
        bytes32 _defaultAdminRole = bytes32(0x00);
        vm.prank(deployer);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(_defaultAdminRole, deployer, deployer);
        TokenStake(payable(proxy)).initialize(
            deployer,
            CONTRACT_URI,
            forwarders(),
            rewardToken,
            stakingToken,
            timeUnit,
            3,
            rewardRatioDenominator
        );
    }

    function test_initialize_emitContractURIUpdated()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenRewardStakingTokenNotSame
        whenStakingTokenNotZeroAddress
        whenStakingDecimalsDoNotEqualZero
        whenRewardTokenDecimalsNotEqualZero
        whenStakingTokenIsNotNativeToken
        whenRewardTokenIsNotNativeToken
        whenTimeUnitDoesNotEqualZero
    {
        vm.expectEmit(true, true, true, false);
        emit ContractURIUpdated("", CONTRACT_URI);
        TokenStake(payable(proxy)).initialize(
            deployer,
            CONTRACT_URI,
            forwarders(),
            rewardToken,
            stakingToken,
            timeUnit,
            3,
            rewardRatioDenominator
        );
    }
}
