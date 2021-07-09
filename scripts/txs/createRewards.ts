import * as dotenv from 'dotenv';
dotenv.config();

import { ethers } from 'hardhat';
import { Contract, Wallet } from 'ethers';

import { accessPacksObj } from '../../utils/contracts';

// Transaction parameters.
const rewardURIs: string[] = [
  "ipfs://QmUEfhF9FpucMVfjySnDmFvq3nKwGNtNk83qDwMEt3JDCL",
  "ipfs://QmXmp3FWWELBwb7wxRD98ps96iYRUXUycPvd1LQ23WhRhW",
  "ipfs://QmUxgEgxvFeiJHAMLK9oWpS6yZmR8EzyJpzQmCc2Gv99U6"
]
const rewardSupplies: number[] = [5, 10, 20];

async function createRewards(rewardURIs: string[], rewardSupplies: number[]) {
  
  // Get Wallet instance.
  const rinkebyProvider = new ethers.providers.JsonRpcProvider(`https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`, "rinkeby");
  const privateKey = process.env.TEST_PRIVATE_KEY || "";
  const rinkebyWallet: Wallet = new ethers.Wallet(privateKey, rinkebyProvider);

  // Get contract instance connected to wallet.
  const accessPacks: Contract = new ethers.Contract(accessPacksObj.address, accessPacksObj.abi, rinkebyWallet);

  // Create rewards.
  const createRewardsTx = await accessPacks.createNativeRewards(rewardURIs, rewardSupplies);
  console.log("Creating rewards: ", createRewardsTx.hash);
  await createRewardsTx.wait();
}

createRewards(rewardURIs, rewardSupplies)
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  })