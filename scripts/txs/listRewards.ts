import * as dotenv from 'dotenv';
dotenv.config();

import { ethers } from 'hardhat';
import { Wallet, Contract, BigNumber } from 'ethers';

import  { marketObj, accessPacksObj } from '../../utils/contracts';

// Transaction parameters.
const rewardContract = accessPacksObj.address;
const rewardId: BigNumber = BigNumber.from(2);
const saleCurrency: string = "0x0000000000000000000000000000000000000000";
const salePrice: BigNumber = ethers.utils.parseEther("0.01");
const quantityToSell: BigNumber = BigNumber.from(6);

async function listRewards(
  rewardContract: string,
  tokenId: BigNumber,
  currency: string,
  pricePerToken: BigNumber,
  quantityToSell: BigNumber
) {
  
  // Setting manual gas limit.
  const manualGasLimit: number = 1000000; // 1 mil

  // Get Wallet instance.
  const rinkebyProvider = new ethers.providers.JsonRpcProvider(`https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`, "rinkeby");
  const privateKey = process.env.TEST_PRIVATE_KEY || "";
  const rinkebyWallet: Wallet = new ethers.Wallet(privateKey, rinkebyProvider);

  // Get contract instances conencted with wallet.
  const market: Contract = new ethers.Contract(marketObj.address, marketObj.abi, rinkebyWallet);
  const accessPacks: Contract = new ethers.Contract(accessPacksObj.address, accessPacksObj.abi, rinkebyWallet);

  // Approve Market to transfer reward tokens.
  const approveMarketTx = await accessPacks.setApprovalForAll(market.address, true);
  console.log("Approving Market for pack tokens: ", approveMarketTx.hash);
  await approveMarketTx.wait()

  // List reward tokens on sale.
  const listRewardsTx = await market.listRewards(rewardContract, tokenId, currency, pricePerToken, quantityToSell, {
    gasLimit: manualGasLimit
  });
  console.log("Listing rewards for sale: ", listRewardsTx.hash)
  await listRewardsTx.wait();
}

listRewards(
  rewardContract,
  rewardId,
  saleCurrency,
  salePrice,
  quantityToSell
).then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  });