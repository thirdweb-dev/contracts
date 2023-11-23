// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";
import { ERC20Vote } from "contracts/base/ERC20Vote.sol";

contract MyVoteERC20 is VoteERC20 {
    function eip712NameHash() external view returns (bytes32) {
        return _EIP712NameHash();
    }

    function eip712VersionHash() external view returns (bytes32) {
        return _EIP712VersionHash();
    }
}

contract VoteERC20Test_Initialize is BaseTest {
    address payable public implementation;
    address payable public proxy;
    address public token;
    uint256 public initialVotingDelay;
    uint256 public initialVotingPeriod;
    uint256 public initialProposalThreshold;
    uint256 public initialVoteQuorumFraction;

    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);
    event ProposalThresholdSet(uint256 oldProposalThreshold, uint256 newProposalThreshold);
    event QuorumNumeratorUpdated(uint256 oldQuorumNumerator, uint256 newQuorumNumerator);

    function setUp() public override {
        super.setUp();

        // Deploy voting token
        token = address(new ERC20Vote(deployer, "Voting VoteERC20", "VT"));

        // Voting param initial values
        initialVotingDelay = 5;
        initialVotingPeriod = 10;
        initialProposalThreshold = 100;
        initialVoteQuorumFraction = 50;

        // Deploy implementation.
        implementation = payable(address(new MyVoteERC20()));

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = payable(
            address(
                new TWProxy(
                    implementation,
                    abi.encodeCall(
                        VoteERC20.initialize,
                        (
                            NAME,
                            CONTRACT_URI,
                            forwarders(),
                            token,
                            initialVotingDelay,
                            initialVotingPeriod,
                            initialProposalThreshold,
                            initialVoteQuorumFraction
                        )
                    )
                )
            )
        );
    }

    function test_initialize_initializingImplementation() public {
        vm.expectRevert("Initializable: contract is already initialized");
        VoteERC20(implementation).initialize(
            NAME,
            CONTRACT_URI,
            forwarders(),
            token,
            initialVotingDelay,
            initialVotingPeriod,
            initialProposalThreshold,
            initialVoteQuorumFraction
        );
    }

    modifier whenNotImplementation() {
        _;
    }

    function test_initialize_proxyAlreadyInitialized() public whenNotImplementation {
        vm.expectRevert("Initializable: contract is already initialized");
        MyVoteERC20(proxy).initialize(
            NAME,
            CONTRACT_URI,
            forwarders(),
            token,
            initialVotingDelay,
            initialVotingPeriod,
            initialProposalThreshold,
            initialVoteQuorumFraction
        );
    }

    modifier whenProxyNotInitialized() {
        proxy = payable(address(new TWProxy(implementation, "")));
        _;
    }

    function test_initialize() public whenNotImplementation whenProxyNotInitialized {
        MyVoteERC20(proxy).initialize(
            NAME,
            CONTRACT_URI,
            forwarders(),
            token,
            initialVotingDelay,
            initialVotingPeriod,
            initialProposalThreshold,
            initialVoteQuorumFraction
        );

        // check state
        MyVoteERC20 voteContract = MyVoteERC20(proxy);

        assertEq(voteContract.eip712NameHash(), keccak256(bytes(NAME)));
        assertEq(voteContract.eip712VersionHash(), keccak256(bytes("1")));

        address[] memory _trustedForwarders = forwarders();
        for (uint256 i = 0; i < _trustedForwarders.length; i++) {
            assertTrue(voteContract.isTrustedForwarder(_trustedForwarders[i]));
        }

        assertEq(voteContract.name(), NAME);
        assertEq(voteContract.contractURI(), CONTRACT_URI);
        assertEq(voteContract.votingDelay(), initialVotingDelay);
        assertEq(voteContract.votingPeriod(), initialVotingPeriod);
        assertEq(voteContract.proposalThreshold(), initialProposalThreshold);
        assertEq(voteContract.quorumNumerator(), initialVoteQuorumFraction);
        assertEq(address(voteContract.token()), token);
    }

    function test_initialize_event_VotingDelaySet() public whenNotImplementation whenProxyNotInitialized {
        vm.expectEmit(false, false, false, true);
        emit VotingDelaySet(0, initialVotingDelay);
        MyVoteERC20(proxy).initialize(
            NAME,
            CONTRACT_URI,
            forwarders(),
            token,
            initialVotingDelay,
            initialVotingPeriod,
            initialProposalThreshold,
            initialVoteQuorumFraction
        );
    }

    function test_initialize_event_VotingPeriodSet() public whenNotImplementation whenProxyNotInitialized {
        vm.expectEmit(false, false, false, true);
        emit VotingPeriodSet(0, initialVotingPeriod);
        MyVoteERC20(proxy).initialize(
            NAME,
            CONTRACT_URI,
            forwarders(),
            token,
            initialVotingDelay,
            initialVotingPeriod,
            initialProposalThreshold,
            initialVoteQuorumFraction
        );
    }

    function test_initialize_event_ProposalThresholdSet() public whenNotImplementation whenProxyNotInitialized {
        vm.expectEmit(false, false, false, true);
        emit ProposalThresholdSet(0, initialProposalThreshold);
        MyVoteERC20(proxy).initialize(
            NAME,
            CONTRACT_URI,
            forwarders(),
            token,
            initialVotingDelay,
            initialVotingPeriod,
            initialProposalThreshold,
            initialVoteQuorumFraction
        );
    }

    function test_initialize_event_QuorumNumeratorUpdated() public whenNotImplementation whenProxyNotInitialized {
        vm.expectEmit(false, false, false, true);
        emit QuorumNumeratorUpdated(0, initialVoteQuorumFraction);
        MyVoteERC20(proxy).initialize(
            NAME,
            CONTRACT_URI,
            forwarders(),
            token,
            initialVotingDelay,
            initialVotingPeriod,
            initialProposalThreshold,
            initialVoteQuorumFraction
        );
    }
}
