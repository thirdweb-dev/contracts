// from: https://github.com/ethereumvex/SushiMaker-bridge-exploit/blob/master/utils/utils.js
const hre = require("hardhat");
require('dotenv').config();

const WETH_USDC_UNI = {
    name: 'WETH_USDC_UNI',
    tokenA: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
    tokenB: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
    pair: '0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc'
}

const WETH_USDT_UNI = {
    name: 'WETH_USDT_UNI',
    tokenA: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
    tokenB: "0xdac17f958d2ee523a2206206994597c13d831ec7",
    pair: "0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852"
}

const WETH_DAI_UNI = {
    name: 'WETH_DAI_UNI',
    tokenA: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
    tokenB: "0x6b175474e89094c44da98b954eedeac495271d0f",
    pair: "0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11"
}

const WETH_USDC_SUSHI = {
    name: 'WETH_USDC_SUSHI',
    tokenA: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
    tokenB: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
    pair: '0x397FF1542f962076d0BFE58eA045FfA2d347ACa0'
}

const WETH_USDT_SUSHI = {
    name: 'WETH_USDT_SUSHI',
    tokenA: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
    tokenB: "0xdac17f958d2ee523a2206206994597c13d831ec7",
    pair: "0x06da0fd433C1A5d7a4faa01111c044910A184553"
}

const WETH_DAI_SUSHI = {
    name: 'WETH_DAI_SUSHI',
    tokenA: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
    tokenB: "0x6b175474e89094c44da98b954eedeac495271d0f",
    pair: "0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f"
}

const pairs = [
    WETH_USDC_UNI,
    WETH_USDT_UNI,
    WETH_DAI_UNI,
    WETH_USDC_SUSHI,
    WETH_USDT_SUSHI,
    WETH_DAI_SUSHI
]

const forkFrom = async (blockNumber) => {  
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: process.env.ALCHEMY_ENDPOINT_MAINNET,
            blockNumber: blockNumber,
          },
        },
      ],
    });
};

const impersonate = async function getImpersonatedSigner(address) {
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [address]
    });
    return ethers.provider.getSigner(address);
}

module.exports = [pairs, forkFrom, impersonate];