import "dotenv/config";
import hre, { ethers } from "hardhat";
import { nativeTokenWrapper } from "../../../utils/nativeTokenWrapper";
import { PluginMap, DirectListingsLogic, EnglishAuctionsLogic, OffersLogic, MarketplaceV3 } from "typechain";

import MarketplaceV3ABI from "artifacts/contracts/marketplace/entrypoint/MarketplaceV3.sol/MarketplaceV3.json";
import PluginMapABI from "artifacts/contracts/extension/plugin/PluginMap.sol/PluginMap.json";
import { readFileSync } from "fs";
import { exec } from "child_process";
import { SDKOptionsSchema } from "@thirdweb-dev/sdk";

type PluginMapInput = {
  functionSelector: string;
  functionSignature: string;
  pluginAddress: string;
};

const getFunctionSignature = (fnInputs: any): string => {
  return (
    "(" +
    fnInputs
      .map((i: any) => {
        return i.type === "tuple" ? getFunctionSignature(i.components) : i.type;
      })
      .join(",") +
    ")"
  );
};

const generatePluginFunctions = (pluginAddress: string, pluginAbi: any): PluginMapInput[] => {
  const pluginInterface = new ethers.utils.Interface(pluginAbi);
  const pluginFunctions = [];
  // TODO - filter out common functions like _msgSender(), contractType(), etc.
  for (const fnFragment of Object.values(pluginInterface.functions)) {
    const fn = pluginInterface.getFunction(fnFragment.name);
    if (fn.name.includes("_")) {
      continue;
    }
    pluginFunctions.push({
      functionSelector: pluginInterface.getSighash(fn),
      functionSignature: fn.name + getFunctionSignature(fn.inputs),
      pluginAddress: pluginAddress,
    });
  }
  return pluginFunctions;
};

// Setup marketplace-v3 for tests
async function setupMarketplaceV3(
  pluginsDirectListings: PluginMapInput[],
  pluginsEnglishAuctions: PluginMapInput[],
  pluginsOffers: PluginMapInput[],
) {
  const nativeTokenWrapperAddress = nativeTokenWrapper[hre.network.config.chainId as number];
  console.log("native token wrapper: ", nativeTokenWrapperAddress);
  console.log();

  // Direct Listings
  console.log("deploying direct listings");
  const directListingsLogicDeployer = await ethers
    .getContractFactory("DirectListingsLogic")
    .then(f => f.deploy(nativeTokenWrapperAddress));
  const directListingsLogic: DirectListingsLogic = await directListingsLogicDeployer.deployed();
  console.log(`deployed direct listings: ${directListingsLogic.address}`);
  // console.log("Verifying direct listings.");
  // await verify(directListingsLogic.address, [nativeTokenWrapperAddress]);
  console.log();

  // English Auctions
  console.log("deploying english auctions");
  const englishAuctionsLogicDeployer = await ethers
    .getContractFactory("EnglishAuctionsLogic")
    .then(f => f.deploy(nativeTokenWrapperAddress));
  const englishAuctionsLogic: EnglishAuctionsLogic = await englishAuctionsLogicDeployer.deployed();
  console.log(`deployed english auctions: ${englishAuctionsLogic.address}`);
  // console.log("Verifying english auctions.");
  // await verify(englishAuctionsLogic.address, [nativeTokenWrapperAddress]);
  console.log();

  // Offers
  console.log("deploying offers");
  const offersLogicDeployer = await ethers.getContractFactory("OffersLogic").then(f => f.deploy());
  const offersLogic: OffersLogic = await offersLogicDeployer.deployed();
  console.log(`deployed offers: ${offersLogic.address}`);
  // console.log("Verifying offers.");
  // await verify(offersLogic.address, []);
  console.log();

  // Plugin Map
  console.log("deploying plugin map");
  const directListingsData = pluginsDirectListings.map(i => {
    return {
      ...i,
      pluginAddress: directListingsLogic.address,
    };
  });
  const englishAuctionsData = pluginsEnglishAuctions.map(i => {
    return {
      ...i,
      pluginAddress: englishAuctionsLogic.address,
    };
  });
  const offersData = pluginsOffers.map(i => {
    return {
      ...i,
      pluginAddress: offersLogic.address,
    };
  });
  const mapInput = [...directListingsData, ...englishAuctionsData, ...offersData];
  console.log("map input: ", mapInput);
  console.log();
  const pluginMapDeployer = await ethers.getContractFactory("PluginMap").then(f => f.deploy(mapInput));
  const pluginMap: PluginMap = await pluginMapDeployer.deployed();
  console.log(`deployed plugin map: ${pluginMap.address}`);
  // console.log("Verifying map.");
  // await verify(pluginMap.address, [mapInput]);
  console.log();

  // MarketplaceV3
  console.log("deploying marketplace router");
  const marketplaceV3Deployer = await ethers.getContractFactory("MarketplaceV3").then(f => f.deploy(pluginMap.address));
  const marketplaceV3: MarketplaceV3 = await marketplaceV3Deployer.deployed();
  console.log(`deployed marketplace-v3: ${marketplaceV3.address}`);
  // console.log("Verifying marketplace-v3.");
  // await verify(marketplaceV3.address, [pluginMap.address]);
  console.log();
}

async function main() {
  console.log("setting up marketplace-v3");

  const DirectListingsLogicABI = JSON.parse(
    readFileSync(
      "artifacts/contracts/marketplace/direct-listings/DirectListingsLogic.sol/DirectListingsLogic.json",
      "utf-8",
    ),
  ).abi;
  const pluginsDirectListings = generatePluginFunctions("", DirectListingsLogicABI);

  const EnglishAuctionsLogicABI = JSON.parse(
    readFileSync(
      "artifacts/contracts/marketplace/english-auctions/EnglishAuctionsLogic.sol/EnglishAuctionsLogic.json",
      "utf-8",
    ),
  ).abi;
  const pluginsEnglishAuctions = generatePluginFunctions("", EnglishAuctionsLogicABI);

  const OffersLogicABI = JSON.parse(
    readFileSync("artifacts/contracts/marketplace/offers/OffersLogic.sol/OffersLogic.json", "utf-8"),
  ).abi;
  const pluginsOffers = generatePluginFunctions("", OffersLogicABI);

  await setupMarketplaceV3(pluginsDirectListings, pluginsEnglishAuctions, pluginsOffers);
  console.log("completed");
}

async function verify(address: string, args: any[]) {
  try {
    return await hre.run("verify:verify", {
      address: address,
      constructorArguments: args,
    });
  } catch (e) {
    console.log(address, args, e);
  }
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
