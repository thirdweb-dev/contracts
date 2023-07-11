import { ChainId } from "@thirdweb-dev/sdk";
import dotenv from "dotenv";

dotenv.config();

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
  [84531]: "base-goerli",
  [8453]: "base",
};

export const chainIdApiKey: Record<number, string | undefined> = {
  [ChainId.Mumbai]: process.env.POLYGONSCAN_API_KEY || process.env.SCAN_API_KEY,
  [ChainId.Goerli]: process.env.ETHERSCAN_API_KEY || process.env.SCAN_API_KEY,
  [ChainId.Polygon]: process.env.POLYGONSCAN_API_KEY || process.env.SCAN_API_KEY,
  [ChainId.Mainnet]: process.env.ETHERSCAN_API_KEY || process.env.SCAN_API_KEY,
  [ChainId.Optimism]: process.env.OPTIMISM_SCAN_API_KEY || process.env.SCAN_API_KEY,
  [ChainId.OptimismGoerli]: process.env.OPTIMISM_SCAN_API_KEY || process.env.SCAN_API_KEY,
  [ChainId.Arbitrum]: process.env.ARBITRUM_SCAN_API_KEY || process.env.SCAN_API_KEY,
  [ChainId.ArbitrumGoerli]: process.env.ARBITRUM_SCAN_API_KEY || process.env.SCAN_API_KEY,
  [ChainId.Fantom]: process.env.FANTOMSCAN_API_KEY || process.env.SCAN_API_KEY,
  [ChainId.FantomTestnet]: process.env.FANTOMSCAN_API_KEY || process.env.SCAN_API_KEY,
  [ChainId.Avalanche]: process.env.SNOWTRACE_API_KEY || process.env.SCAN_API_KEY,
  [ChainId.AvalancheFujiTestnet]: process.env.SNOWTRACE_API_KEY || process.env.SCAN_API_KEY,
  [ChainId.BinanceSmartChainMainnet]: process.env.BINANCE_SCAN_API_KEY || process.env.SCAN_API_KEY,
  [ChainId.BinanceSmartChainTestnet]: process.env.BINANCE_SCAN_API_KEY || process.env.SCAN_API_KEY,
  [84531]: "" as string,
  [8453]: "" as string,
};

export const apiMap: Record<number, string> = {
  1: "https://api.etherscan.io/api",
  5: "https://api-goerli.etherscan.io/api",
  10: "https://api-optimistic.etherscan.io/api",
  56: "https://api.bscscan.com/api",
  97: "https://api-testnet.bscscan.com/api",
  137: "https://api.polygonscan.com/api",
  250: "https://api.ftmscan.com/api",
  420: "https://api-goerli-optimistic.etherscan.io/api",
  4002: "https://api-testnet.ftmscan.com/api",
  42161: "https://api.arbiscan.io/api",
  43113: "https://api-testnet.snowtrace.io/api",
  43114: "https://api.snowtrace.io/api",
  421613: "https://api-goerli.arbiscan.io/api",
  80001: "https://api-testnet.polygonscan.com/api",
  84531: "https://api-goerli.basescan.org/api",
  8453: "https://api.basescan.org/api",
};

export const contractsToDeploy = [
  "DropERC721",
  "DropERC1155",
  "DropERC20",
  "TokenERC20",
  "TokenERC721",
  "TokenERC1155",
  "MarketplaceV3",
  "Split",
  "VoteERC20",
  "NFTStake",
  "TokenStake",
  "EditionStake",
];
