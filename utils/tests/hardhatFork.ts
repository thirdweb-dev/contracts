// from: https://github.com/ethereumvex/SushiMaker-bridge-exploit/blob/master/utils/utils.js
import hre from "hardhat";
import { chainIds } from "../chainIds";

const ethers = hre.ethers;
require("dotenv").config();

const defaultForkBlock = 9414004; // randomly set

export const forkFrom = async (network: string, forkBlock?: number) => {
  let alchemyKey: string = process.env.ALCHEMY_KEY || "";

  const polygonNetworkName = network === "polygon" ? "mainnet" : "mumbai";

  let nodeUrl =
    chainIds[network as keyof typeof chainIds] == 137 || chainIds[network as keyof typeof chainIds] == 80001
      ? `https://polygon-${polygonNetworkName}.g.alchemy.com/v2/${alchemyKey}`
      : `https://eth-${network}.alchemyapi.io/v2/${alchemyKey}`;

  if (network === "avax") {
    nodeUrl = "https://api.avax.network/ext/bc/C/rpc";
  } else if (network === "avax_testnet") {
    nodeUrl = "https://api.avax-test.network/ext/bc/C/rpc";
  } else if (network === "fantom") {
    nodeUrl = "https://rpc.ftm.tools";
  } else if (network === "fantom_testnet") {
    nodeUrl = "https://rpc.testnet.fantom.network";
  }

  await hre.network.provider.request({
    method: "hardhat_reset",
    params: [
      {
        forking: {
          jsonRpcUrl: nodeUrl,
          blockNumber: forkBlock || defaultForkBlock,
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
