// from: https://github.com/ethereumvex/SushiMaker-bridge-exploit/blob/master/utils/utils.js
import hre from "hardhat";
import { chainIds } from "../chainIds";

const ethers = hre.ethers;
require("dotenv").config();

const defaultForkBlock = 9414004; // randomly set

export const forkFrom = async (network: keyof typeof chainIds) => {
  let alchemyKey: string = process.env.ALCHEMY_KEY || "";

  let nodeUrl: string =
    chainIds[network] == 137 || chainIds[network] == 80001
      ? network == "polygon"
        ? `https://polygon-mainnet.g.alchemy.com/v2/${alchemyKey}`
        : `https://polygon-mumbai.g.alchemy.com/v2/${alchemyKey}`
      : `https://eth-${network}.alchemyapi.io/v2/${alchemyKey}`;

  await hre.network.provider.request({
    method: "hardhat_reset",
    params: [
      {
        forking: {
          jsonRpcUrl: nodeUrl,
          blockNumber: defaultForkBlock,
        },
      },
    ],
  });
};

export const impersonate = async function getImpersonatedSigner(address: any) {
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [address],
  });
  return ethers.provider.getSigner(address);
};
