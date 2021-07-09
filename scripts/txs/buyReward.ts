import * as dotenv from 'dotenv';
dotenv.config();

import { ethers } from 'hardhat';
import { Wallet, Contract, BigNumber } from 'ethers';

import { marketObj, accessPacksObj } from '../../utils/contracts';

// Transaction parameters.
const rewardContract: string = "0xB98C0E788fb82297a73E32296e246653390eCE68";
const from: string = "0x2Ee4c2e9666Ff48DE2779EB6f33cDC342d761372";
const rewardId: BigNumber = BigNumber.from(2);
const quantityToBuy: BigNumber = BigNumber.from(1);
const salePrice: BigNumber = ethers.utils.parseEther("0.01");

async function buyReward(
  rewardContract: string,
  from: string,
  rewardId: BigNumber,
  quantityToBuy: BigNumber,
  pricePerToken: BigNumber
) {

  // Setting manual gas limit.
  const manualGasLimit: number = 1000000; // 1 mil

  // Get Wallet instance.
  const rinkebyProvider = new ethers.providers.JsonRpcProvider(`https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`, "rinkeby");
  const privateKey = process.env.TEST_PRIVATE_KEY || "";
  const rinkebyWallet: Wallet = new ethers.Wallet(privateKey, rinkebyProvider);

  // Get contract instances conencted with wallet.
  const market: Contract = new ethers.Contract(marketObj.address, marketObj.abi, rinkebyWallet);

  // Calculate price to pay i.e. ether value to send in transaction.
  const priceToPay: BigNumber = quantityToBuy.mul(pricePerToken);

  // Buy reward tokens.
  const buyTx = await market.buyRewards(rewardContract, from, rewardId, quantityToBuy, { gasLimit: manualGasLimit, value: priceToPay });
  console.log("Buying rewards: ", buyTx.hash);
  await buyTx.wait();
}

buyReward(
  rewardContract,
  from,
  rewardId,
  quantityToBuy,
  salePrice
).then(() => process.exit(1))
  .catch(err => {
    console.error(err)
    process.exit(1)
  });