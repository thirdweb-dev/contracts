// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";
import { ERC20Vote } from "contracts/base/ERC20Vote.sol";

contract MyVoteERC20 is VoteERC20 {}

contract VoteERC20Test_SetContractURI is BaseTest {
    address payable public implementation;
    address payable public proxy;
    address internal caller;
    string internal _contractURI;

    address public token;
    uint256 public initialVotingDelay;
    uint256 public initialVotingPeriod;
    uint256 public initialProposalThreshold;
    uint256 public initialVoteQuorumFraction;

    uint256 public proposalId;
    address[] public targets;
    uint256[] public values;
    bytes[] public calldatas;
    string public description;

    MyVoteERC20 internal voteContract;

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
    }

    function _createProposalForSetContractURI() internal {
        description = "set contract URI";

        bytes memory data = abi.encodeWithSelector(VoteERC20.setContractURI.selector, _contractURI);

        targets.push(address(voteContract));
        values.push(0);
        calldatas.push(data);

        vm.prank(deployer);
        proposalId = voteContract.propose(targets, values, calldatas, description);
    }

    function test_setContractURI_callerNotAuthorized() public {
        vm.prank(address(0x123));
        vm.expectRevert("Governor: onlyGovernance");
        voteContract.setContractURI(_contractURI);
    }

    modifier whenCallerAuthorized() {
        vm.roll(2);
        _createProposalForSetContractURI();
        _;
    }

    function test_setContractURI_empty() public whenCallerAuthorized {
        vm.roll(10);
        // first try execute without votes
        vm.expectRevert("Governor: proposal not successful");
        voteContract.execute(targets, values, calldatas, keccak256(bytes(description)));

        // vote on proposal
        vm.prank(caller);
        voteContract.castVote(proposalId, 1);

        // execute
        vm.roll(200); // deadline must be over, before execute can be called
        voteContract.execute(targets, values, calldatas, keccak256(bytes(description)));

        // check state: get contract uri
        assertEq(voteContract.contractURI(), _contractURI);
    }
}
