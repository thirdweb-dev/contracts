import * as dotenv from 'dotenv';
dotenv.config();

import { ethers } from 'hardhat';
import { Wallet, Contract, BigNumber } from 'ethers';

import { packObj, rewardsObj } from '../../utils/contracts';

// Transaction parameters.
const rewardContract = rewardsObj.address;
const packURI = "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1";
const rewardIds: number[] = [36,37,38]
const rewardSupplies: number[] = [5, 10, 20];
const openStartAndEnd: number = 0;

async function createPack(
  rewardContract: string,
  packURI: string,
  rewardIds: number[],
  rewardSupplies: number[],

  openStart: number,
  openEnd: number
) {

  const manualGasPrice: BigNumber = ethers.utils.parseEther("0.000000005");

  // Get Wallet instance.
  const mumbaiProvider = new ethers.providers.JsonRpcProvider(`https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`);
  const privateKey = process.env.TEST_PRIVATE_KEY || "";
  const mumbaiWallet: Wallet = new ethers.Wallet(privateKey, mumbaiProvider);

  // Get contract instances connected to wallet.
  const pack: Contract = new ethers.Contract(packObj.address, packObj.abi, mumbaiWallet);
  const rewards: Contract = new ethers.Contract(rewardsObj.address, rewardsObj.abi, mumbaiWallet);

  // Approve Handler to transfer reward tokens.
  const approveHandlerTx = await rewards.setApprovalForAll(pack.address, true, { gasPrice: manualGasPrice});
  console.log("Approving Handler for reward tokens: ", approveHandlerTx.hash);
  await approveHandlerTx.wait()

  // Create packs with rewards and list packs for sale.
  const createPackTx = await pack.createPack(
    packURI,
    rewardContract,
    rewardIds,
    rewardSupplies,
    openStart,
    openEnd,
    { gasPrice: manualGasPrice}
  );
  console.log("Create pack: ", createPackTx.hash);
  await createPackTx.wait();
}

createPack(
  rewardContract,
  packURI,
  rewardIds,
  rewardSupplies,
  openStartAndEnd,
  openStartAndEnd
).then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  })