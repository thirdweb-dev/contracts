import { ethers } from "hardhat";
import { Contract, BigNumber } from "ethers";

import { addresses } from "../../utils/contracts";

/// NOTE: set the right network you want.

// Transaction parameters.
const rewardURIs: string[] = [
  "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1",
  "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/2",
  "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/3",
];
const rewardSupplies: number[] = [5, 10, 20];

async function createRewards(rewardURIs: string[], rewardSupplies: number[]) {
  const manualGasPrice: BigNumber = ethers.utils.parseUnits("5", "gwei");

  // Get signer.
  const [caller] = await ethers.getSigners();

  // Get contract instance connected to wallet.
  const {
    mumbai: { rewards },
  } = addresses;
  const rewardsContract: Contract = await ethers.getContractAt("Rewards", rewards);

  // Create rewards.
  const createRewardsTx = await rewardsContract
    .connect(caller)
    .createNativeRewards(rewardURIs, rewardSupplies, { gasPrice: manualGasPrice });
  console.log("Creating rewards: ", createRewardsTx.hash);
  await createRewardsTx.wait();
}

createRewards(rewardURIs, rewardSupplies)
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
