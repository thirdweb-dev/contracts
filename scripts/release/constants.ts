import { ChainId, CONTRACT_ADDRESSES } from "@thirdweb-dev/sdk";

export const nativeTokenWrapper: Record<number, string> = {
  1: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", // mainnet
  5: "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6", // goerli
  137: "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270", // polygon
  80001: "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889", // mumbai
  43114: "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7", // avalanche
  43113: "0xd00ae08403B9bbb9124bB305C09058E32C39A48c", // avalanche fuji testnet
  250: "0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83", // fantom
  4002: "0xf1277d1Ed8AD466beddF92ef448A132661956621", // fantom testnet
  10: "0x4200000000000000000000000000000000000006", // optimism
  420: "0x4200000000000000000000000000000000000006", // optimism goerli
  42161: "0x82af49447d8a07e3bd95bd0d56f35241523fbab1", // arbitrum
  421613: "0xe39Ab88f8A4777030A534146A9Ca3B52bd5D43A3", // arbitrum goerli
};

export const chainIdToName: Record<number, string> = {
  [ChainId.Mumbai]: "mumbai",
  [ChainId.Goerli]: "goerli",
  [ChainId.Polygon]: "polygon",
  [ChainId.Mainnet]: "mainnet",
  [ChainId.Optimism]: "optimism",
  [ChainId.OptimismGoerli]: "optimism-goerli",
  [ChainId.Arbitrum]: "arbitrum",
  [ChainId.ArbitrumGoerli]: "arbitrum-goerli",
  [ChainId.Fantom]: "fantom",
  [ChainId.FantomTestnet]: "fantom-testnet",
  [ChainId.Avalanche]: "avalanche",
  [ChainId.AvalancheFujiTestnet]: "avalanche-testnet",
  [ChainId.BinanceSmartChainMainnet]: "binance",
  [ChainId.BinanceSmartChainTestnet]: "binance-testnet",
};

export const defaultFactories: Record<number, string> = {
  [ChainId.Mainnet]: CONTRACT_ADDRESSES[ChainId.Mainnet].twFactory,
  [ChainId.Goerli]: CONTRACT_ADDRESSES[ChainId.Goerli].twFactory,
  [ChainId.Polygon]: CONTRACT_ADDRESSES[ChainId.Polygon].twFactory,
  [ChainId.Mumbai]: CONTRACT_ADDRESSES[ChainId.Mumbai].twFactory,
  [ChainId.Fantom]: CONTRACT_ADDRESSES[ChainId.Fantom].twFactory,
  [ChainId.FantomTestnet]: CONTRACT_ADDRESSES[ChainId.FantomTestnet].twFactory,
  [ChainId.Optimism]: CONTRACT_ADDRESSES[ChainId.Optimism].twFactory,
  [ChainId.OptimismGoerli]: CONTRACT_ADDRESSES[ChainId.OptimismGoerli].twFactory,
  [ChainId.Arbitrum]: CONTRACT_ADDRESSES[ChainId.Arbitrum].twFactory,
  [ChainId.ArbitrumGoerli]: CONTRACT_ADDRESSES[ChainId.ArbitrumGoerli].twFactory,
  [ChainId.Avalanche]: CONTRACT_ADDRESSES[ChainId.Avalanche].twFactory,
  [ChainId.AvalancheFujiTestnet]: CONTRACT_ADDRESSES[ChainId.AvalancheFujiTestnet].twFactory,
  [ChainId.BinanceSmartChainMainnet]: CONTRACT_ADDRESSES[ChainId.BinanceSmartChainMainnet].twFactory,
  [ChainId.BinanceSmartChainTestnet]: CONTRACT_ADDRESSES[ChainId.BinanceSmartChainTestnet].twFactory,
};
