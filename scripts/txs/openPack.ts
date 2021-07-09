import * as dotenv from 'dotenv';
dotenv.config();

import { ethers } from 'hardhat';
import { Wallet, Contract, BigNumber } from 'ethers';

import { handlerObj, packObj } from '../../utils/contracts';

// Transaction parameters.
const packId: BigNumber = BigNumber.from(0);

async function openPack(packId: BigNumber) {

  // Setting manual gas limit.
  const manualGasLimit: number = 1000000; // 1 mil

  // Get Wallet instance.
  const rinkebyProvider = new ethers.providers.JsonRpcProvider(`https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`, "rinkeby");
  const privateKey = process.env.TEST_PRIVATE_KEY || "";
  const rinkebyWallet: Wallet = new ethers.Wallet(privateKey, rinkebyProvider);

  // Get contract instance connected to wallet.
  const pack: Contract = new ethers.Contract(packObj.address, packObj.abi, rinkebyWallet);
  const handler: Contract = new ethers.Contract(handlerObj.address, handlerObj.abi, rinkebyWallet);

  // Approve Handler to transfer pack tokens.
  const approveHandlerTx = await pack.setApprovalForAll(handler.address, true);
  console.log("Approving Handler to burn pack tokens: ", approveHandlerTx.hash);
  await approveHandlerTx.wait()

  // Open pack.
  const openTx = await handler.openPack(packId, { gasLimit: manualGasLimit });
  console.log("Opening pack: ", openTx.hash);
  await openTx.wait();
}

openPack(packId)
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  })
