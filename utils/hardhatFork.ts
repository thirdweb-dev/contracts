// from: https://github.com/ethereumvex/SushiMaker-bridge-exploit/blob/master/utils/utils.js
import hre from "hardhat";
const ethers = hre.ethers;
require("dotenv").config();

const chainIds = {
  mainnet: 1,
  rinkeby: 4,

  matic: 137,
  mumbai: 80001,
};

export const forkFrom = async (blockNumber: any, network: keyof typeof chainIds) => {
  let alchemyKey: string = process.env.ALCHEMY_KEY || "";

  let nodeUrl: string =
    chainIds[network] == 137 || chainIds[network] == 80001
      ? `https://polygon-${network}.g.alchemy.com/v2/${alchemyKey}`
      : `https://eth-${network}.alchemyapi.io/v2/${alchemyKey}`;

  await hre.network.provider.request({
    method: "hardhat_reset",
    params: [
      {
        forking: {
          jsonRpcUrl: nodeUrl,
          blockNumber: blockNumber,
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
