// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";
import { ERC20Vote } from "contracts/base/ERC20Vote.sol";

contract MyVoteERC20 is VoteERC20 {}

contract VoteERC20Test_Propose is BaseTest {
    address payable public implementation;
    address payable public proxy;
    address internal caller;
    string internal _contractURI;

    address public token;
    uint256 public initialVotingDelay;
    uint256 public initialVotingPeriod;
    uint256 public initialProposalThreshold;
    uint256 public initialVoteQuorumFraction;

    uint256 public proposalIdOne;
    address[] public targetsOne;
    uint256[] public valuesOne;
    bytes[] public calldatasOne;
    string public descriptionOne;

    uint256 public proposalIdTwo;
    address[] public targetsTwo;
    uint256[] public valuesTwo;
    bytes[] public calldatasTwo;
    string public descriptionTwo;

    MyVoteERC20 internal voteContract;

    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    function setUp() public override {
        super.setUp();

        // Deploy voting token
        vm.prank(deployer);
        token = address(new ERC20Vote(deployer, "Voting VoteERC20", "VT"));

        // Voting param initial values
        initialVotingDelay = 1;
        initialVotingPeriod = 100;
        initialProposalThreshold = 10;
        initialVoteQuorumFraction = 1;

        // Deploy implementation.
        implementation = payable(address(new MyVoteERC20()));

        caller = getActor(1);

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

        voteContract = MyVoteERC20(proxy);
        _contractURI = "ipfs://contracturi";

        // mint governance tokens
        vm.startPrank(deployer);
        ERC20Vote(token).mintTo(caller, 100);
        ERC20Vote(token).mintTo(deployer, 100);
        vm.stopPrank();

        // delegate votes to self
        vm.prank(caller);
        ERC20Vote(token).delegate(caller);
        vm.prank(deployer);
        ERC20Vote(token).delegate(deployer);

        vm.roll(2);

        // create first proposal
        _createProposalOne();
    }

    function _createProposalOne() internal {
        descriptionOne = "set proposal one";

        bytes memory data = abi.encodeWithSelector(VoteERC20.setContractURI.selector, _contractURI);

        targetsOne.push(address(voteContract));
        valuesOne.push(0);
        calldatasOne.push(data);

        vm.prank(deployer);
        proposalIdOne = voteContract.propose(targetsOne, valuesOne, calldatasOne, descriptionOne);
    }

    function _setupProposalTwo() internal {
        descriptionTwo = "set proposal two";

        bytes memory data = abi.encodeWithSelector(VoteERC20.setContractURI.selector, _contractURI);

        targetsTwo.push(address(voteContract));
        valuesTwo.push(0);
        calldatasTwo.push(data);
    }

    function test_propose_votesBelowThreshold() public {
        _setupProposalTwo();

        vm.prank(address(0x123)); // random address that doesn't have threshold votes
        vm.expectRevert("Governor: proposer votes below proposal threshold");
        voteContract.propose(targetsTwo, valuesTwo, calldatasTwo, descriptionTwo);
    }

    modifier hasThresholdVotes() {
        _;
    }

    function test_propose_emptyTargets() public hasThresholdVotes {
        address[] memory _targets;
        uint256[] memory _values;
        bytes[] memory _calldatas;
        string memory _description;

        vm.prank(caller);
        vm.expectRevert("Governor: empty proposal");
        voteContract.propose(_targets, _values, _calldatas, _description);
    }

    modifier whenNotEmptyTargets() {
        _;
    }

    function test_propose_lengthMismatchTargetsValues() public hasThresholdVotes whenNotEmptyTargets {
        _setupProposalTwo();

        uint256[] memory _values;

        vm.prank(caller);
        vm.expectRevert("Governor: invalid proposal length");
        voteContract.propose(targetsTwo, _values, calldatasTwo, descriptionTwo);
    }

    modifier whenTargetValuesEqualLength() {
        _;
    }

    function test_propose_lengthMismatchTargetsCalldatas()
        public
        hasThresholdVotes
        whenNotEmptyTargets
        whenTargetValuesEqualLength
    {
        _setupProposalTwo();

        bytes[] memory _calldatas;

        vm.prank(caller);
        vm.expectRevert("Governor: invalid proposal length");
        voteContract.propose(targetsTwo, valuesTwo, _calldatas, descriptionTwo);
    }

    modifier whenTargetCalldatasEqualLength() {
        _;
    }

    function test_propose_proposalAlreadyExists()
        public
        hasThresholdVotes
        whenNotEmptyTargets
        whenTargetValuesEqualLength
        whenTargetCalldatasEqualLength
    {
        // creating proposalOne again

        vm.prank(caller);
        vm.expectRevert("Governor: proposal already exists");
        voteContract.propose(targetsOne, valuesOne, calldatasOne, descriptionOne);
    }

    modifier whenProposalNotAlreadyExists() {
        _;
    }

    function test_propose()
        public
        hasThresholdVotes
        whenNotEmptyTargets
        whenTargetValuesEqualLength
        whenTargetCalldatasEqualLength
        whenProposalNotAlreadyExists
    {
        _setupProposalTwo();

        vm.prank(caller);
        proposalIdTwo = voteContract.propose(targetsTwo, valuesTwo, calldatasTwo, descriptionTwo);

        assertEq(voteContract.proposalSnapshot(proposalIdTwo), voteContract.votingDelay() + block.number);
        assertEq(
            voteContract.proposalDeadline(proposalIdTwo),
            voteContract.proposalSnapshot(proposalIdTwo) + voteContract.votingPeriod()
        );
        assertEq(voteContract.proposalIndex(), 2); // because two proposals have been created
        assertEq(voteContract.getAllProposals().length, 2);

        (
            uint256 _proposalId,
            address _proposer,
            uint256 _startBlock,
            uint256 _endBlock,
            string memory _description
        ) = voteContract.proposals(1);

        assertEq(_proposalId, proposalIdTwo);
        assertEq(_proposer, caller);
        assertEq(_startBlock, voteContract.proposalSnapshot(proposalIdTwo));
        assertEq(_endBlock, voteContract.proposalDeadline(proposalIdTwo));
        assertEq(_description, descriptionTwo);
    }

    function test_propose_event_ProposalCreated()
        public
        hasThresholdVotes
        whenNotEmptyTargets
        whenTargetValuesEqualLength
        whenTargetCalldatasEqualLength
        whenProposalNotAlreadyExists
    {
        _setupProposalTwo();
        uint256 _expectedProposalId = voteContract.hashProposal(
            targetsTwo,
            valuesTwo,
            calldatasTwo,
            keccak256(bytes(descriptionTwo))
        );
        string[] memory signatures = new string[](targetsTwo.length);

        vm.startPrank(caller);
        vm.expectEmit(false, false, false, true);
        emit ProposalCreated(
            _expectedProposalId,
            caller,
            targetsTwo,
            valuesTwo,
            signatures,
            calldatasTwo,
            voteContract.votingDelay() + block.number,
            voteContract.votingDelay() + block.number + voteContract.votingPeriod(),
            descriptionTwo
        );
        voteContract.propose(targetsTwo, valuesTwo, calldatasTwo, descriptionTwo);
        vm.stopPrank();
    }
}
