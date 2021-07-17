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
  address: "0xb08E08f4B0A88eaFc1446e703390Ad49dB7507e8",
  abi: controlCenterAbi
}

export const packObj = {
  address: "0x5ECC47810De05F49728Abe629f59FF020D4b5d92",
  abi: packABI
}

export const marketObj = {
  address: "0x9e3880045597a3eaAfB1E1589Ea2711efc5B252d",
  abi: marketAbi
}

export const rngObj = {
  address: "0xc0afa9B5F59830EA4921D5789A403b3724a2334C",
  abi: rngAbi
}

export const rewardsObj = {
  address: "0xD3207F46a7C1ABf8bF22E43056521B9d22758E65",
  abi: rewardsABI
}

export const rinkebyProvider = new ethers.providers.JsonRpcProvider(
  `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
  "rinkeby"
);

export const privateKey = process.env.TEST_PRIVATE_KEY || ""

export const rinkebyWallet = new ethers.Wallet(privateKey, rinkebyProvider);


