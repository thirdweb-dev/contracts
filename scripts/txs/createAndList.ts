import * as dotenv from 'dotenv';
dotenv.config();

import { ethers } from 'hardhat';
import { Wallet, Contract, BigNumber } from 'ethers';

import { packObj, handlerObj, marketObj, accessPacksObj } from '../../utils/contracts';

// Transaction parameters.
const rewardContract = accessPacksObj.address;
const packURI = "ipfs://QmbJx772DtMCNpgwDaggZEwBS3C8eCucahgfvUVCzWrHUp";
const rewardIds: BigNumber[] = [BigNumber.from(0), BigNumber.from(1), BigNumber.from(2)];
const rewardSupplies: BigNumber[] = [BigNumber.from(5), BigNumber.from(10), BigNumber.from(15)];
const saleCurrency: string = "0x0000000000000000000000000000000000000000"; // ether.
const salePrice: BigNumber = ethers.utils.parseEther("0.01");

async function createAndListPacks(
  rewardContract: string,
  packURI: string,
  rewardIds: BigNumber[],
  rewardSupplies: BigNumber[],

  saleCurrency: string,
  salePrice: BigNumber
) {

  // Get Wallet instance.
  const rinkebyProvider = new ethers.providers.JsonRpcProvider(`https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`, "rinkeby");
  const privateKey = process.env.TEST_PRIVATE_KEY || "";
  const rinkebyWallet: Wallet = new ethers.Wallet(privateKey, rinkebyProvider);

  // Get contract instances connected to wallet.
  const pack: Contract = new ethers.Contract(packObj.address, packObj.abi, rinkebyWallet);
  const handler: Contract = new ethers.Contract(handlerObj.address, handlerObj.abi, rinkebyWallet);
  const accessPacks: Contract = new ethers.Contract(accessPacksObj.address, accessPacksObj.abi, rinkebyWallet);

  // Approve Handler to transfer reward tokens.
  const approveHandlerTx = await accessPacks.setApprovalForAll(handler.address, true);
  console.log("Approving Handler for reward tokens: ", approveHandlerTx.hash);
  await approveHandlerTx.wait()

  // Approve Market to transfer pack tokens.
  const approveMarketTx = await pack.setApprovalForAll(marketObj.address, true);
  console.log("Approving Market for pack tokens: ", approveMarketTx.hash);
  await approveMarketTx.wait()

  // Create packs with rewards and list packs for sale.
  const createPackAndListTx = await handler.createPackAndList(
    rewardContract,
    packURI,
    rewardIds,
    rewardSupplies,
    saleCurrency,
    salePrice
  );
  console.log("Create and list packs for sale: ", createPackAndListTx.hash);
  await createPackAndListTx.wait();
}

createAndListPacks(
  rewardContract,
  packURI,
  rewardIds,
  rewardSupplies,
  saleCurrency,
  salePrice
).then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  })