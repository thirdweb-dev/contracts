import { ethers } from "ethers";
import * as dotenv from "dotenv";
dotenv.config();

export const addresses = {
  matic: {
    controlCenter: "0x429ACf993C992b322668122a5fC5593200493ea8",
    pack: "0x3d5a51975fD29E45Eb285349F12b77b4c153c8e0",
    market: "0xfC958641E52563f071534495886A8Ac590DCBFA2",
    rewards: "0x58408Fa085ae3942C3A6532ee6215bFC7f80c47A",
  },
  mumbai: {
    controlCenter: "0x932a80d12133daDa78d1eFeAa69C53f35b7717eB",
    pack: "0xdF6D4D22918048bA57e849dBBc83d9Bb502bb150",
    market: "0x420dF8F7659cad7b9701b882E5A0f0282c49907d",
    rewards: "0xe9559e34a8A32FA8Dc050fAaFD9343B666BC92CF",
  },
  rinkeby: {
    controlCenter: "0x916a0c502Ea07B50e48c5c5D6e6C5e26E6F04e02",
    pack: "0xcD6c2E7439C712464B8D49DD6369C976894EbAdb",
    market: "0x87Fe40CAC2Ba4b2d8d5639Ea712Bab6C294e5454",
    rewards: "0x906f3c4643F0C721eB48A40d3903043B43C43434",
  },
  mainnet: {
    controlCenter: "",
    pack: "",
    market: "",
    rewards: "",
  },
};

export const provider = (network: string) =>
  new ethers.providers.JsonRpcProvider(`https://eth-${network}.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`, network);

export const privateKey = process.env.TEST_PRIVATE_KEY || "";

export const wallet = (network: string) => new ethers.Wallet(privateKey, provider(network));
