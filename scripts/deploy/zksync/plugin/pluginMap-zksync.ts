import { Wallet, Provider, ContractFactory } from "zksync-ethers";
import * as hre from "hardhat";
import dotenv from "dotenv";
import { ZkSyncArtifact } from "@matterlabs/hardhat-zksync-solc/dist/src/types";

import "@matterlabs/hardhat-zksync-node/dist/type-extensions";
import "@matterlabs/hardhat-zksync-verify/dist/src/type-extensions";
import { ethers } from "ethers";

dotenv.config();

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
    if (fn.name.startsWith("_")) {
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

async function getPluginInput() {
  const DirectListingsLogicArtifact: ZkSyncArtifact = (await hre.artifacts.readArtifact(
    "DirectListingsLogic",
  )) as ZkSyncArtifact;
  const pluginsDirectListings = generatePluginFunctions(
    "0x26279882D5E93045D4FA986847CAAC048b2Bac3b",
    DirectListingsLogicArtifact.abi,
  );

  const EnglishAuctionsLogicArtifact: ZkSyncArtifact = (await hre.artifacts.readArtifact(
    "EnglishAuctionsLogic",
  )) as ZkSyncArtifact;
  const pluginsEnglishAuctions = generatePluginFunctions(
    "0xf3C7d3F0AA374a2D32489929e24D3e9313Aec8bb",
    EnglishAuctionsLogicArtifact.abi,
  );

  const OffersLogicABI: ZkSyncArtifact = (await hre.artifacts.readArtifact("OffersLogic")) as ZkSyncArtifact;
  const pluginsOffers = generatePluginFunctions("0x56Abb6a3f25DCcdaDa106191053b1CC54C196DEE", OffersLogicABI.abi);

  return [...pluginsDirectListings, ...pluginsEnglishAuctions, ...pluginsOffers];
}

async function main() {
  const pluginInput = await getPluginInput();

  const provider = new Provider(hre.network.config.url);
  const wallet = new Wallet(`${process.env.TEST_PRIVATE_KEY}`, provider);
  const artifact: ZkSyncArtifact = (await hre.artifacts.readArtifact("PluginMap")) as ZkSyncArtifact;
  const map = new ContractFactory(artifact.abi, artifact.bytecode, wallet, "create");

  const contract = await map.deploy(pluginInput);
  await contract.deployed();

  console.log("Deployed PluginMap \n: ", contract.address);
  console.log("\n");
  console.log("Verifying contract.");

  // deployed address zksync mainnet: 0x0326643B8844710065C9ce0e5326B006608E8D8d
  // deployed address zksync sepolia: 0xC2f4B1B6B3d6813aBc8e55B3BAd0796526A5d633
  // deployed address abstract testnet: 0xa6344b5B22c13444Ed46709fE810108Bc14BdB2b
  // deployed address lens testnet: 0x6dc0A7c9c0E79883345e2384B7619EA1D1199C3C
  // xsolla testnet: 0xf415B06d4C62F03066DA67C2c6401818701EE430
  // abstract mainnet: 
  await verify(contract.address, "contracts/extension/plugin/PluginMap.sol:PluginMap", [pluginInput]);
}

async function verify(address: string, contract: string, args: any[]) {
  try {
    return await hre.run("verify:verify", {
      address: address,
      contract: contract,
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
