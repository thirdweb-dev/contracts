import { ethers } from "ethers";
import * as dotenv from "dotenv";
import { chainIds } from "./chainIds";

dotenv.config();

export async function getContractAddress(
  name: "controlCenter" | "pack" | "market" | "rewards", 
  chainId: number
)  {
  for (let network of Object.keys(chainIds)) {
    if (chainIds[(network as keyof typeof chainIds)] == chainId) {
      return addresses[(network as keyof typeof addresses)][name];
    }
  }
}

export const addresses = {
  matic: {
    controlCenter: "0x429ACf993C992b322668122a5fC5593200493ea8",
    pack: "0x3d5a51975fD29E45Eb285349F12b77b4c153c8e0",
    market: "0xfC958641E52563f071534495886A8Ac590DCBFA2",
    rewards: "0x58408Fa085ae3942C3A6532ee6215bFC7f80c47A",
  },
  mumbai: {
    controlCenter: "0x3d86dD9846c0a15B0f40037AAf51CC68A4236add",
    pack: "0xD89eE4F34BC76315E77D808305c0931f28Fa3C5D",
    market: "0xF1089C7a0Ae7d0729d94ff6806d7BeA0A02C3bF2",
    rewards: "0x7c6c7048Cd447BA200bde9A89A2ECc83435b7E51",
  },
  rinkeby: {
    controlCenter: "0xAFe8f8EDad3Fd7b0108997b51CCd24286FbF000B",
    pack: "0x928C9EE38048e5D0A4601D1FDcF7B9E57317278D",
    market: "0xE0C0158A9d498EF4D0b02a8256A6957718Af8B5B",
    rewards: "0xebC0b11f62A416634fe400bbB750f0E40833a4d0",
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
