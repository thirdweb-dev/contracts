import hre, { run, ethers } from "hardhat";
import { Contract } from "ethers";

/**
 enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }
 */

async function main() {
  const [proposer, recipient, burner] = await ethers.getSigners();

  const CoinFactory = await ethers.getContractFactory("Coin");
  const VotingGovernorFactory = await ethers.getContractFactory("VotingGovernor");
  //const TimelockControllerFactory = await ethers.getContractFactory("TimelockController");

  const controlAddress = ethers.constants.AddressZero;
  const forwarderAddress = ethers.constants.AddressZero;
  const uri = "";

  const coin = await CoinFactory.deploy(controlAddress, "DAO20", "DAO20", forwarderAddress, uri);
  const proposers = [ethers.constants.AddressZero];
  const executors = [ethers.constants.AddressZero];
  //const timelock = await TimelockControllerFactory.deploy(0, proposers, executors);

  const initialVotingDelay = "0";
  const initialVotingPeriod = "1"; // 1800 blocks * 2 second block time =  60 minutes
  const initialProposalThreshold = "0";
  const initialVoteQuorumFraction = "1"; // 1%
  const governor = await VotingGovernorFactory.deploy(
    "Hey Governor",
    coin.address,
    initialVotingDelay,
    initialVotingPeriod,
    initialProposalThreshold,
    initialVoteQuorumFraction,
    forwarderAddress,
    uri,
  );

  ////// setting up making sure governor has minter role
  await coin.grantRole(ethers.utils.id("MINTER_ROLE"), governor.address);

  ////// note, need to DELEGATE tokens before creating Proposal because it's snapshotted.
  await coin.mint(proposer.address, ethers.utils.parseUnits("2"));
  await coin.mint(burner.address, ethers.utils.parseUnits("99"));
  await coin.delegate(proposer.address);

  ////// Create a Proposal
  const targets = [coin.address]; // address
  const values = [0]; // 0
  const calldatas = [coin.interface.encodeFunctionData("mint", [recipient.address, ethers.utils.parseUnits("5")])]; // interface encode
  const description = "prop";
  const txProposal = await (await governor.propose(targets, values, calldatas, description)).wait();
  const eventProposalCreated = (txProposal.events && txProposal.events[0]) || ([] as any);
  console.log("ProposalCreated", eventProposalCreated.args);

  ////// GetAll proposal with ids, states and votes
  const proposalIds = (await governor.queryFilter(governor.filters.ProposalCreated())).map(tx => tx.args.proposalId);
  const porposalStates = await Promise.all(proposalIds.map(pId => governor.state(pId)));
  const proposalVotes = await Promise.all(proposalIds.map(pId => governor.proposalVotes(pId)));
  console.log(proposalIds[0].toString(), porposalStates[0], proposalVotes[0]);

  ////// Vote on a Proposal
  enum Vote {
    AGAINST = 0,
    FOR = 1,
    ABSTAIN = 2,
  }
  const voteReason = "pumpkin";
  const txVote = await (await governor.castVoteWithReason(proposalIds[0], Vote.FOR, voteReason)).wait();
  const eventVoteCast = (txVote.events && txVote.events[0]) || ([] as any);
  console.log("VoteCast", eventVoteCast.args);

  // error cause vote casted
  // const txVote2 = await (await governor.castVoteWithReason(proposalIds[0], Vote.AGAINST, voteReason)).wait();
  // console.log("VoteCast2", txVote2);

  // did the proposal update?
  const proposalIds2 = (await governor.queryFilter(governor.filters.ProposalCreated())).map(tx => tx.args.proposalId);
  const porposalStates2 = await Promise.all(proposalIds.map(pId => governor.state(pId)));
  const proposalVotes2 = await Promise.all(proposalIds.map(pId => governor.proposalVotes(pId)));
  console.log(proposalIds2[0].toString(), porposalStates2[0], proposalVotes2[0]);

  //console.log(await governor.queryFilter(governor.filters.ProposalCreated()));

  ////// Execute on a Proposal
  await governor.execute(targets, values, calldatas, ethers.utils.id(description));
}

main();
