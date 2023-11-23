// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MySplit is Split {}

contract SplitTest_Initialize is BaseTest {
    address payable public implementation;
    address payable public proxy;

    address[] public payees;
    uint256[] public shares;

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    function setUp() public override {
        super.setUp();

        // create 5 payees and shares
        for (uint160 i = 0; i < 5; i++) {
            payees.push(getActor(i + 100));
            shares.push(i + 100);
        }

        // Deploy implementation.
        implementation = payable(address(new MySplit()));

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = payable(
            address(
                new TWProxy(
                    implementation,
                    abi.encodeCall(Split.initialize, (deployer, CONTRACT_URI, forwarders(), payees, shares))
                )
            )
        );
    }

    function test_initialize_initializingImplementation() public {
        vm.expectRevert("Initializable: contract is already initialized");
        Split(implementation).initialize(deployer, CONTRACT_URI, forwarders(), payees, shares);
    }

    modifier whenNotImplementation() {
        _;
    }

    function test_initialize_proxyAlreadyInitialized() public whenNotImplementation {
        vm.expectRevert("Initializable: contract is already initialized");
        MySplit(proxy).initialize(deployer, CONTRACT_URI, forwarders(), payees, shares);
    }

    modifier whenProxyNotInitialized() {
        proxy = payable(address(new TWProxy(implementation, "")));
        _;
    }

    function test_initialize_payeeLengthZero() public whenNotImplementation whenProxyNotInitialized {
        address[] memory _payees;
        uint256[] memory _shares;
        vm.expectRevert("PaymentSplitter: no payees");
        MySplit(proxy).initialize(deployer, CONTRACT_URI, forwarders(), _payees, _shares);
    }

    modifier whenPayeeLengthNotZero() {
        _;
    }

    function test_initialize_payeesSharesUnequalLength()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenPayeeLengthNotZero
    {
        uint256[] memory _shares;
        vm.expectRevert("PaymentSplitter: payees and shares length mismatch");
        MySplit(proxy).initialize(deployer, CONTRACT_URI, forwarders(), payees, _shares);
    }

    modifier whenEqualLengths() {
        _;
    }

    function test_initialize()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenPayeeLengthNotZero
        whenEqualLengths
    {
        MySplit(proxy).initialize(deployer, CONTRACT_URI, forwarders(), payees, shares);

        // check state
        MySplit splitContract = MySplit(proxy);

        address[] memory _trustedForwarders = forwarders();
        for (uint256 i = 0; i < _trustedForwarders.length; i++) {
            assertTrue(splitContract.isTrustedForwarder(_trustedForwarders[i]));
        }

        uint256 totalShares;
        for (uint160 i = 0; i < 5; i++) {
            uint256 _shares = splitContract.shares(payees[i]);
            assertEq(_shares, shares[i]);

            totalShares += _shares;
        }
        assertEq(totalShares, splitContract.totalShares());
        assertEq(splitContract.payeeCount(), payees.length);
        assertEq(splitContract.contractURI(), CONTRACT_URI);
        assertTrue(splitContract.hasRole(bytes32(0x00), deployer));
    }

    function test_initialize_event_RoleGranted_DefaultAdmin()
        public
        whenNotImplementation
        whenProxyNotInitialized
        whenPayeeLengthNotZero
        whenEqualLengths
    {
        bytes32 _defaultAdminRole = bytes32(0x00);
        vm.prank(deployer);
        vm.expectEmit(true, true, true, false);
        emit RoleGranted(_defaultAdminRole, deployer, deployer);
        MySplit(proxy).initialize(deployer, CONTRACT_URI, forwarders(), payees, shares);
    }
}
