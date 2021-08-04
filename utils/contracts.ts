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
  address: "0x1F7B09caE043b76AdF7BD3aB27D181e8f363Fab8",
  abi: controlCenterAbi
}

export const packObj = {
  address: "0xAeAd01CF2280E5B55B62F7fa621cA63c8d6af029",
  abi: packABI
}

export const marketObj = {
  address: "0xdE2624Ac39A13bb08F316f3156c2d707a8B479A3",
  abi: marketAbi
}

export const rngObj = {
  address: "0xb90518CEaee065beAC311733CBC4EF41FC6f520C",
  abi: rngAbi
}

export const rewardsObj = {
  address: "0x4B2F4f0e9197401dE59f001a782B517E6F0A4aac",
  abi: rewardsABI
}

export const rinkebyProvider = new ethers.providers.JsonRpcProvider(
  `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
  "rinkeby"
);

export const privateKey = process.env.TEST_PRIVATE_KEY || ""

export const rinkebyWallet = new ethers.Wallet(privateKey, rinkebyProvider);


