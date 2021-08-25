import { ethers } from "ethers";
import * as dotenv from "dotenv";
dotenv.config();

export const addresses = {
  matic: {
    controlCenter: "0x35d9fD7AA4b49028a5EB83F0E48c3ea99bE23124",
    pack: "0x78EFd532b02a142A9376182cd3372973401f9110",
    market: "0x63025410F6463Bf87c36565D843b7FCdDF16d753",
    rewards: "0x32AE8E62494951c0c758131F28220B3d30a90258",
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
