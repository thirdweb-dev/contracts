import dotenv from "dotenv";
import { SUPPORTED_CHAIN_ID, ThirdwebSDK } from "@thirdweb-dev/sdk";
import { nativeTokenWrapper } from "../../../utils/nativeTokenWrapper";
import { chainIdToName } from "../../release/constants";
import { readFileSync, writeFileSync } from "fs";
import { ethers } from "ethers";

dotenv.config();

const uri = "ipfs://Qmc7oig9R4rEDB2UXBpivHCsuUh39KnrBhYbfcUwo9sAoo";
const privateKey: string = process.env.DEPLOYER_KEY as string;

const targetNetworkName = process.argv[2] as string;
if (!targetNetworkName) {
  console.log("Provide network name");
  process.exit(1);
}

let targetNetworkId: string = "";
for (const chainId of Object.keys(chainIdToName)) {
  if (chainIdToName[parseInt(chainId) as SUPPORTED_CHAIN_ID] === targetNetworkName) {
    targetNetworkId = chainId;
  }
}

if (!targetNetworkId) {
  console.log("Invalid network");
  process.exit(1);
}

const sdk = ThirdwebSDK.fromPrivateKey(privateKey, targetNetworkName);

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
  const pluginAddresses = JSON.parse(readFileSync("scripts/plugin/plugin/pluginAddress.json", "utf-8"));
  const nativeTokenWrapperAddress = nativeTokenWrapper[parseInt(targetNetworkId)];
  console.log("native token wrapper: ", nativeTokenWrapperAddress);
  console.log();

  // Direct Listings
  let directListingsLogicAddress = pluginAddresses[targetNetworkId]["DirectListingsLogic"];
  if (!directListingsLogicAddress) {
    console.log("deploying direct listings");
    try {
      directListingsLogicAddress = await sdk.deployer.deployContractFromUri(`${uri}/0`, [nativeTokenWrapperAddress]);
    } catch (e) {
      writeFileSync("scripts/plugin/plugin/pluginAddress.json", JSON.stringify(pluginAddresses), "utf-8");
      console.log("error: ", e);
      process.exit(1);
    }
    console.log(`deployed direct listings: ${directListingsLogicAddress}`);
    // console.log("Verifying direct listings.");
    // await verify(directListingsLogic.address, [nativeTokenWrapperAddress]);
    console.log();

    pluginAddresses[targetNetworkId]["DirectListingsLogic"] = directListingsLogicAddress;
  }

  // English Auctions
  let englishAuctionsLogicAddress = pluginAddresses[targetNetworkId]["EnglishAuctionsLogic"];
  if (!englishAuctionsLogicAddress) {
    console.log("deploying english auctions");
    try {
      englishAuctionsLogicAddress = await sdk.deployer.deployContractFromUri(`${uri}/1`, [nativeTokenWrapperAddress]);
    } catch (e) {
      writeFileSync("scripts/plugin/plugin/pluginAddress.json", JSON.stringify(pluginAddresses), "utf-8");
      console.log("error: ", e);
      process.exit(1);
    }
    console.log(`deployed english auctions: ${englishAuctionsLogicAddress}`);
    // console.log("Verifying english auctions.");
    // await verify(englishAuctionsLogic.address, [nativeTokenWrapperAddress]);
    console.log();

    pluginAddresses[targetNetworkId]["EnglishAuctionsLogic"] = englishAuctionsLogicAddress;
  }

  // Offers
  let offersLogicAddress = pluginAddresses[targetNetworkId]["OffersLogic"];
  if (!offersLogicAddress) {
    console.log("deploying offers");
    try {
      offersLogicAddress = await sdk.deployer.deployContractFromUri(`${uri}/3`, []);
    } catch (e) {
      writeFileSync("scripts/plugin/plugin/pluginAddress.json", JSON.stringify(pluginAddresses), "utf-8");
      console.log("error: ", e);
      process.exit(1);
    }
    console.log(`deployed offers: ${offersLogicAddress}`);
    // console.log("Verifying offers.");
    // await verify(offersLogic.address, []);
    console.log();
    pluginAddresses[targetNetworkId]["OffersLogic"] = offersLogicAddress;
  }

  // Plugin Map
  let pluginMapAddress = pluginAddresses[targetNetworkId]["PluginMap"];
  if (!pluginMapAddress) {
    console.log("deploying plugin map");
    const directListingsData = pluginsDirectListings.map(i => {
      return {
        ...i,
        pluginAddress: directListingsLogicAddress,
      };
    });
    const englishAuctionsData = pluginsEnglishAuctions.map(i => {
      return {
        ...i,
        pluginAddress: englishAuctionsLogicAddress,
      };
    });
    const offersData = pluginsOffers.map(i => {
      return {
        ...i,
        pluginAddress: offersLogicAddress,
      };
    });
    const mapInput = [...directListingsData, ...englishAuctionsData, ...offersData];
    console.log("map input: ", mapInput);
    console.log();
    try {
      pluginMapAddress = await sdk.deployer.deployContractFromUri(`${uri}/4`, [mapInput]);
    } catch (e) {
      writeFileSync("scripts/plugin/plugin/pluginAddress.json", JSON.stringify(pluginAddresses), "utf-8");
      console.log("error: ", e);
      process.exit(1);
    }
    console.log(`deployed plugin map: ${pluginMapAddress}`);
    // console.log("Verifying map.");
    // await verify(pluginMap.address, [mapInput]);
    console.log();

    pluginAddresses[targetNetworkId]["PluginMap"] = pluginMapAddress;
  }

  // MarketplaceV3
  let marketplaceV3Address = pluginAddresses[targetNetworkId]["MarketplaceV3"];
  if (!marketplaceV3Address) {
    console.log("deploying marketplace router");
    try {
      marketplaceV3Address = await sdk.deployer.deployContractFromUri(`${uri}/2`, [pluginMapAddress]);
    } catch (e) {
      writeFileSync("scripts/plugin/plugin/pluginAddress.json", JSON.stringify(pluginAddresses), "utf-8");
      console.log("error: ", e);
      process.exit(1);
    }
    console.log(`deployed marketplace-v3: ${marketplaceV3Address}`);
    // console.log("Verifying marketplace-v3.");
    // await verify(marketplaceV3.address, [pluginMap.address]);
    console.log();

    pluginAddresses[targetNetworkId]["MarketplaceV3"] = marketplaceV3Address;
  }

  writeFileSync("scripts/plugin/plugin/pluginAddress.json", JSON.stringify(pluginAddresses), "utf-8");
}

async function main() {
  console.log("setting up marketplace-v3");

  const DirectListingsLogicABI = JSON.parse(
    readFileSync("artifacts_forge/DirectListingsLogic.sol/DirectListingsLogic.json", "utf-8"),
  ).abi;
  const pluginsDirectListings = generatePluginFunctions("", DirectListingsLogicABI);

  const EnglishAuctionsLogicABI = JSON.parse(
    readFileSync("artifacts_forge/EnglishAuctionsLogic.sol/EnglishAuctionsLogic.json", "utf-8"),
  ).abi;
  const pluginsEnglishAuctions = generatePluginFunctions("", EnglishAuctionsLogicABI);

  const OffersLogicABI = JSON.parse(readFileSync("artifacts_forge/OffersLogic.sol/OffersLogic.json", "utf-8")).abi;
  const pluginsOffers = generatePluginFunctions("", OffersLogicABI);

  await setupMarketplaceV3(pluginsDirectListings, pluginsEnglishAuctions, pluginsOffers);
  console.log("completed");
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
