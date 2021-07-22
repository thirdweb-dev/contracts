import { ethers } from 'ethers';
import * as dotenv from 'dotenv'
dotenv.config();

import controlCenterAbi from '../abi/ProtocolControl.json';
import packABI from '../abi/Pack.json';
import marketAbi  from '../abi/Market.json';
import rngAbi from '../abi/RNG.json';
import rewardsABI from '../abi/Rewards.json';

dotenv.config();

export const controlCenterObj = {
  address: "0x653CB7AA740f17116Ab709e0f2bD6Db4941f5855",
  abi: controlCenterAbi
}

export const packObj = {
  address: "0x22B9fdC2fCeE92675Ab9398F42251A6A2cd8f7A1",
  abi: packABI
}

export const marketObj = {
  address: "0x908dF092CDa0a3c6D7326F483113fcFc0BF892f8",
  abi: marketAbi
}

export const rngObj = {
  address: "0x65D5D86562A478F1EbdB9b45b8E27179Bfd1A9df",
  abi: rngAbi
}

export const rewardsObj = {
  address: "0x87e54ac75a7f29dfB763Db4D752749E01E308c10",
  abi: rewardsABI
}

export const rinkebyProvider = new ethers.providers.JsonRpcProvider(
  `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
  "rinkeby"
);

export const privateKey = process.env.TEST_PRIVATE_KEY || ""

export const rinkebyWallet = new ethers.Wallet(privateKey, rinkebyProvider);


