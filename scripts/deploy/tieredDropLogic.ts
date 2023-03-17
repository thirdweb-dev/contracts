import "dotenv/config";
import { readFileSync } from "fs";
import { ethers, BytesLike } from "ethers";
import { JsonFragment } from "@ethersproject/abi";
import hre from "hardhat";

////// To run this script: `npx ts-node scripts/deploy/tieredDrop.ts` //////

// ========== Types ==========

type PluginMetadata = {
  name: string;
  metadataURI: string;
  implementation: string;
}

type PluginFunction = {
  functionSelector: BytesLike;
  functionSignature: string;
}

type Plugin = {
  metadata: PluginMetadata;
  functions: PluginFunction[];
}

// ========== Constants ==========
const MOCAVERSE_ROUTER = "0x59325733eb952a92e069c87f0a6168b29e80627f";
function getABI(contractName: string): JsonFragment[] {
  return JSON.parse(
    readFileSync(`artifacts_forge/${contractName}.sol/${contractName}.json`, "utf-8"),
  ).abi;
}

function generatePluginParam(pluginName: string, contractAddress: string): Plugin {

  const abi = getABI(pluginName);

  const pluginInterface = new ethers.utils.Interface(abi);

  const pluginMetadata: PluginMetadata = {
    name: pluginName,
    metadataURI: "ipfs://QmX3cSXXgGQYu7CqMWLHFCyYNcRqBv164GPpiGoHuCvncg",
    implementation: contractAddress
  };
  const pluginFunctions: PluginFunction[] = [];

  const fragments = pluginInterface.functions;
  for (const fnSignature of Object.keys(fragments)) {
    pluginFunctions.push({
      functionSelector: pluginInterface.getSighash(fragments[fnSignature]),
      functionSignature: fnSignature
    });
  }

  return {
    metadata: pluginMetadata,
    functions: pluginFunctions
  }
}

async function main() {
  // const provider = ethers.getDefaultProvider(NETWORK);
  // const signer = new ethers.Wallet(PRIVATE_KEY, provider);
  // const tieredDropLogicFactory = new TieredDropLogic__factory(signer);
  const tieredDropLogicFactory = await hre.ethers.getContractFactory("TieredDropLogic");
  const tieredDropLogic = await tieredDropLogicFactory.deploy();
  await tieredDropLogic.deployed();
  console.log(`New TieredDropLogic deployed to ${tieredDropLogic.address}`);

  const tieredDropLogicPlugin: Plugin = generatePluginParam("TieredDropLogic", tieredDropLogic.address);
  console.log(tieredDropLogicPlugin);
  // const tieredDropRouter = TieredDrop__factory.connect(MOCAVERSE_ROUTER, signer);
  const tieredDropRouter = await hre.ethers.getContractAt("TieredDrop", MOCAVERSE_ROUTER);
  const updateExtensionTx = await tieredDropRouter.addExtension(tieredDropLogicPlugin);

  console.log("Update Extension Transaction: ", updateExtensionTx);
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });