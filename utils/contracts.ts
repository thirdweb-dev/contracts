import { ethers } from 'ethers';
import * as dotenv from 'dotenv'
dotenv.config();

import controlCenterAbi from '../abi/ControlCenter.json';
import packABI from '../abi/Pack.json';
import handlerABI from '../abi/Handler.json';
import marketAbi  from '../abi/Market.json';
import rngAbi from '../abi/RNG.json';
import assetSafeAbi from '../abi/AssetSafe.json';
import accessPacksABI from '../abi/AccessPacks.json';

dotenv.config();

export const controlCenterObj = {
  address: "0xBF0f4Dc9B3E59a3bF69685D3cE8a04D78675c255",
  abi: controlCenterAbi
}

export const packObj = {
  address: "0x3A6701A5D1cb6Cd2A8886aFFeE3012E2396bA755",
  abi: packABI
}

export const handlerObj = {
  address: "0x87a041FFdf941a305d8d0A581080972ff8e1Fd42",
  abi: handlerABI
}

export const marketObj = {
  address: "0xDd8C26Bb12dc8cC31E572Cc8e83919c4d02fad5e",
  abi: marketAbi
}

export const rngObj = {
  address: "0x38FCAa08CC0ADcFEcfc8488EeB49f67Ab58E4A9A",
  abi: rngAbi
}

export const assetSafeObj = {
  address: "0x9b6962a5a1Bc2E1Fa0508fe933310B51FC6063e1",
  abi: assetSafeAbi
}

export const accessPacksObj = {
  address: "0x16611A37a86B7C35b2d5C316402Ecc24f18B36e2",
  abi: accessPacksABI
}

export const rinkebyProvider = new ethers.providers.JsonRpcProvider(
  `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
  "rinkeby"
);

export const privateKey = process.env.TEST_PRIVATE_KEY || ""

export const rinkebyWallet = new ethers.Wallet(privateKey, rinkebyProvider);


