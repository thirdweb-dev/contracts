import hre, { run, ethers } from "hardhat";
import { Contract } from "ethers";

async function main() {
  const CoinFactory = await ethers.getContractFactory("Coin");
  const VotingGovernorFactory = await ethers.getContractFactory("VotingGovernor");
  const TimelockControllerFactory = await ethers.getContractFactory("TimelockController");

  const controlAddress = ethers.constants.AddressZero;
  const forwarderAddress = ethers.constants.AddressZero;
  const uri = "";

  const coin = await CoinFactory.deploy(controlAddress, "DAO20", "DAO20", forwarderAddress, uri);
  const proposers = [ethers.constants.AddressZero];
  const executors = [ethers.constants.AddressZero];
  const timelock = await TimelockControllerFactory.deploy(0, proposers, executors);

  const initialVotingDelay = "1";
  const initialVotingPeriod = "1";
  const initialProposalThreshold = "0";
  const governor = await VotingGovernorFactory.deploy(
    "Hey Governor",
    coin.address,
    initialVotingDelay,
    initialVotingPeriod,
    initialProposalThreshold,
    forwarderAddress,
    uri,
  );

  // TODO: propose, governor.propose();
  // TODO: get all proposals
  // TODO: vote, governor.castVote(); governor.hasVoted()
  // TODO: execute, governor.execute();
}

main();
