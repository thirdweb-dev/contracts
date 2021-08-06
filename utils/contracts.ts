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
  address: "0x312c3Dd6E0102F872535c3618Ae2Fb3D68C8C087",
  abi: controlCenterAbi
}

export const packObj = {
  address: "0x9C90C6073Cefd64055e4fc6AB9E8127e1a2b44F3",
  abi: packABI
}

export const marketObj = {
  address: "0x1C86CC9D4C79486571B465eB98ee7De8260BDBE6",
  abi: marketAbi
}

export const rngObj = {
  address: "0x31Fe46A9f5046f329a7c4dD5ad87f1A2543390f6",
  abi: rngAbi
}

export const rewardsObj = {
  address: "0xF0D1064ec8Dee772af45D6e9E45Cfa5F429d80a7",
  abi: rewardsABI
}

export const rinkebyProvider = new ethers.providers.JsonRpcProvider(
  `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
  "rinkeby"
);

export const privateKey = process.env.TEST_PRIVATE_KEY || ""

export const rinkebyWallet = new ethers.Wallet(privateKey, rinkebyProvider);


