import * as dotenv from 'dotenv';
dotenv.config();

import { ethers } from 'hardhat';
import { Contract, Wallet, BigNumber } from 'ethers';

import { rewardsObj } from '../../utils/contracts';

// Transaction parameters.
const rewardURIs: string[] = [
  "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1",
  "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/2",
  "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/3"
]
const rewardSupplies: number[] = [5, 10, 20];

async function createRewards(rewardURIs: string[], rewardSupplies: number[]) {
  const manualGasPrice: BigNumber = ethers.utils.parseEther("0.000000005");

  // Get Wallet instance.
  const mumbaiProvider = new ethers.providers.JsonRpcProvider(`https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`);
  const privateKey = process.env.TEST_PRIVATE_KEY || "";
  const mumbaiWallet: Wallet = new ethers.Wallet(privateKey, mumbaiProvider);

  // Get contract instance connected to wallet.
  const rewards: Contract = new ethers.Contract(rewardsObj.address, rewardsObj.abi, mumbaiWallet);

  // Create rewards.
  const createRewardsTx = await rewards.createNativeRewards(rewardURIs, rewardSupplies, { gasPrice: manualGasPrice});
  console.log("Creating rewards: ", createRewardsTx.hash);
  await createRewardsTx.wait();
}

createRewards(rewardURIs, rewardSupplies)
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  })