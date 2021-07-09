import * as dotenv from 'dotenv';
dotenv.config();

import { ethers } from 'hardhat';
import { Wallet, Contract, BigNumber } from 'ethers';


import { marketObj } from '../../utils/contracts';

// Transaction parameters.
const from: string = "0x2Ee4c2e9666Ff48DE2779EB6f33cDC342d761372";
const packId: BigNumber = BigNumber.from(0);
const quantityToBuy: BigNumber = BigNumber.from(1);
const salePrice: BigNumber = ethers.utils.parseEther("0.01");

async function buyPack(from: string, packId: BigNumber, quantityToBuy: BigNumber, pricePerToken: BigNumber) {

  // Setting manual gas limit.
  const manualGasLimit: number = 1000000; // 1 mil
  
  // Get Wallet instance.
  const rinkebyProvider = new ethers.providers.JsonRpcProvider(`https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`, "rinkeby");
  const privateKey = process.env.TEST_PRIVATE_KEY || "";
  const rinkebyWallet: Wallet = new ethers.Wallet(privateKey, rinkebyProvider);

  // Get contract instance connected to wallet.
  const market: Contract = new ethers.Contract(marketObj.address, marketObj.abi, rinkebyWallet);

  // Calculate price to pay i.e. ether value to send in transaction.
  const priceToPay: BigNumber = quantityToBuy.mul(pricePerToken);

  // Buy pack tokens.
  const buyTx = await market.buyPacks(from, packId, quantityToBuy, { gasLimit: manualGasLimit, value: priceToPay });
  console.log("Buying one pack from market listing: ", buyTx.hash);
  await buyTx.wait();
}

buyPack(from, packId, quantityToBuy, salePrice)
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  });