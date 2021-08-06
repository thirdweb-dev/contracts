import * as dotenv from 'dotenv';
dotenv.config();

import { ethers } from 'hardhat';
import { Wallet, Contract, BigNumber } from 'ethers';

import { packObj } from '../../utils/contracts';

// Transaction parameters.
const packId: BigNumber = BigNumber.from(0);

async function openPack(packId: BigNumber) {

  // Setting manual gas limit.
  const manualGasLimit: number = 2000000; // 1 mil
  const manualGasPrice: BigNumber = ethers.utils.parseEther("0.000000005");

  // Get Wallet instance.
  const mumbaiProvider = new ethers.providers.JsonRpcProvider(`https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`);
  const privateKey = process.env.TEST_PRIVATE_KEY || "";
  const mumbaiWallet: Wallet = new ethers.Wallet(privateKey, mumbaiProvider);

  // Get contract instance connected to wallet.
  const pack: Contract = new ethers.Contract(packObj.address, packObj.abi, mumbaiWallet);

  // Open pack.
  const openTx = await pack.openPack(packId, { gasLimit: manualGasLimit, gasPrice: manualGasPrice });
  console.log("Opening pack: ", openTx.hash);
  await openTx.wait();
}

openPack(packId)
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  })
