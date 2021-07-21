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
  address: "0x278f941f4d167E6f75f7607c6ff12d86a2757568",
  abi: controlCenterAbi
}

export const packObj = {
  address: "0xe3c195AeCFefE42c4f5B2332dcd635930cBB494e",
  abi: packABI
}

export const marketObj = {
  address: "0x3C5dDEd0160d4cef316138F21b7Cb0B0A77bBf50",
  abi: marketAbi
}

export const rngObj = {
  address: "0x6782e28dC7009DeFea4B7506A8c9ecA9Fd927e47",
  abi: rngAbi
}

export const rewardsObj = {
  address: "0xc36BEd3Ae0ff500F2D2E918Df90B4d59DFAE9942",
  abi: rewardsABI
}

export const rinkebyProvider = new ethers.providers.JsonRpcProvider(
  `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
  "rinkeby"
);

export const privateKey = process.env.TEST_PRIVATE_KEY || ""

export const rinkebyWallet = new ethers.Wallet(privateKey, rinkebyProvider);


