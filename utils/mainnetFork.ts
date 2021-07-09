// from: https://github.com/ethereumvex/SushiMaker-bridge-exploit/blob/master/utils/utils.js
import hre from "hardhat";
const ethers = hre.ethers;
require('dotenv').config();

export const forkFrom = async (blockNumber: any) => {  
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
            blockNumber: blockNumber,
          },
        },
      ],
    });
};

export const impersonate = async function getImpersonatedSigner(address: any) {
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [address]
    });
    return ethers.provider.getSigner(address);
}