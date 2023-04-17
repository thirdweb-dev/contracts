import dotenv from "dotenv";
import { SUPPORTED_CHAIN_ID, ThirdwebSDK } from "@thirdweb-dev/sdk";
import { nativeTokenWrapper } from "../../../utils/nativeTokenWrapper";
import { eoaForwarder } from "../../../utils/eoaForwarders";
import { chainlinkVars } from "../../../utils/chainlinkUtils";
import { chainIdToName } from "../../release/constants";
import { readFileSync, writeFileSync } from "fs";
import { ethers } from "ethers";

dotenv.config();

const uri = "ipfs://QmbfJPXWm1YeCL2JGtBkXBbodPocV2yhu55tGwHDPjURos";
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

const sdk = ThirdwebSDK.fromPrivateKey(privateKey, targetNetworkName, {
  gasSettings: {
    maxPriceInGwei: 40,
  },
});

type ExtensionMetadata = {
  name: string;
  metadataURI: string;
  implementation: string;
};

type ExtensionFunction = {
  functionSelector: string;
  functionSignature: string;
};

type ExtensionInput = {
  metadata: ExtensionMetadata;
  functions: ExtensionFunction[];
};

const getFunctionSignature = (fnInputs: any): string => {
  return (
    "(" +
    fnInputs
      .map((i: any) => {
        return i.type === "tuple"
          ? getFunctionSignature(i.components)
          : i.type === "tuple[]"
          ? getFunctionSignature(i.components) + `[]`
          : i.type;
      })
      .join(",") +
    ")"
  );
};

const generateExtensionFunctions = (extensionAbi: any): ExtensionFunction[] => {
  const extensionInterface = new ethers.utils.Interface(extensionAbi);
  const extensionFunctions: ExtensionFunction[] = [];
  // TODO - filter out common functions like _msgSender(), contractType(), etc.
  for (const fnFragment of Object.values(extensionInterface.functions)) {
    const fn = extensionInterface.getFunction(fnFragment.name);
    if (fn.name.includes("_")) {
      continue;
    }
    extensionFunctions.push({
      functionSelector: extensionInterface.getSighash(fn),
      functionSignature: fn.name + getFunctionSignature(fn.inputs),
    });
  }
  return extensionFunctions;
};

// Setup pack-vrf
async function setupPackVrf(permissionsExtensions: ExtensionFunction[], packExtensions: ExtensionFunction[]) {
  const extensionAddresses = JSON.parse(readFileSync("scripts/pack-vrf/extension/extensionAddresses.json", "utf-8"));
  const nativeTokenWrapperAddress = nativeTokenWrapper[parseInt(targetNetworkId)];
  const eoaForwarderAddress = eoaForwarder[parseInt(targetNetworkId)];
  const chainLinkVar = Object.entries(chainlinkVars).find(([chain]) => chain === targetNetworkId)?.[1];
  if (!chainLinkVar) {
    console.error("No chainlink data found for chain: ", targetNetworkId);
    process.exit(1);
  }

  console.log("native token wrapper: ", nativeTokenWrapperAddress);
  console.log();

  // PermissionsEnumerableImpl
  let permissionsExtensionAddress = extensionAddresses[targetNetworkId]["PermissionsEnumerableImpl"];
  if (!permissionsExtensionAddress) {
    console.log("deploying PermissionsEnumerableImpl");
    try {
      permissionsExtensionAddress = await sdk.deployer.deployContractFromUri(`${uri}/2`, []);
    } catch (e) {
      writeFileSync("scripts/pack-vrf/extension/extensionAddresses.json", JSON.stringify(extensionAddresses), "utf-8");
      console.log("error: ", e);
      process.exit(1);
    }
    console.log(`deployed PermissionsEnumerableImpl: ${permissionsExtensionAddress}`);
    // console.log("Verifying direct listings.");
    // await verify(directListingsLogic.address, [nativeTokenWrapperAddress]);
    console.log();

    extensionAddresses[targetNetworkId]["PermissionsEnumerableImpl"] = permissionsExtensionAddress;
  }

  // PackVRFDirectLogic
  let packExtensionAddress = extensionAddresses[targetNetworkId]["PackVRFDirectLogic"];
  if (!packExtensionAddress) {
    console.log("deploying PackVRFDirectLogic");
    try {
      packExtensionAddress = await sdk.deployer.deployContractFromUri(`${uri}/0`, [
        nativeTokenWrapperAddress,
        chainLinkVar.linkTokenAddress,
        chainLinkVar.vrfV2Wrapper,
      ]);
    } catch (e) {
      writeFileSync("scripts/pack-vrf/extension/extensionAddresses.json", JSON.stringify(extensionAddresses), "utf-8");
      console.log("error: ", e);
      process.exit(1);
    }
    console.log(`deployed PackVRFDirectLogic: ${packExtensionAddress}`);
    // console.log("Verifying direct listings.");
    // await verify(directListingsLogic.address, [nativeTokenWrapperAddress]);
    console.log();

    extensionAddresses[targetNetworkId]["PackVRFDirectLogic"] = packExtensionAddress;
  }

  // Generate Extension Inputs
  let extensions: ExtensionInput[] = [];
  console.log("deploying plugin map");
  const packExtensionMetadata: ExtensionMetadata = {
    name: "PackVRFDirectLogic",
    metadataURI: "",
    implementation: packExtensionAddress,
  };
  extensions.push({
    metadata: packExtensionMetadata,
    functions: packExtensions,
  });

  const permissionsExtensionMetadata: ExtensionMetadata = {
    name: "PermissionsEnumerableImpl",
    metadataURI: "",
    implementation: permissionsExtensionAddress,
  };
  extensions.push({
    metadata: permissionsExtensionMetadata,
    functions: permissionsExtensions,
  });

  console.log(JSON.stringify(extensions));
  writeFileSync("scripts/pack-vrf/extension/extensions.json", JSON.stringify(extensions), "utf-8");

  // PackVRFDirectRouter
  let packRouterAddress = extensionAddresses[targetNetworkId]["PackVRFDirectRouter"];
  if (!packRouterAddress) {
    console.log("deploying PackVRFDirectRouter");
    try {
      packRouterAddress = await sdk.deployer.deployContractFromUri(`${uri}/1`, [extensions, eoaForwarderAddress], {});
    } catch (e) {
      writeFileSync("scripts/pack-vrf/extension/extensionAddresses.json", JSON.stringify(extensionAddresses), "utf-8");
      console.log("error: ", e);
      process.exit(1);
    }
    console.log(`deployed PackVRFDirectRouter: ${packRouterAddress}`);
    // console.log("Verifying marketplace-v3.");
    // await verify(marketplaceV3.address, [pluginMap.address]);
    console.log();

    extensionAddresses[targetNetworkId]["PackVRFDirectRouter"] = packRouterAddress;
  }

  writeFileSync("scripts/pack-vrf/extension/extensionAddresses.json", JSON.stringify(extensionAddresses), "utf-8");
}

async function main() {
  console.log("setting up pack-vrf");

  const PermissionsEnumerableABI = JSON.parse(
    readFileSync("artifacts_forge/PermissionsEnumerableImpl.sol/PermissionsEnumerableImpl.json", "utf-8"),
  ).abi;
  const permissionsExtensions = generateExtensionFunctions(PermissionsEnumerableABI);

  const PackVRFDirectLogicABI = JSON.parse(
    readFileSync("artifacts_forge/PackVRFDirectLogic.sol/PackVRFDirectLogic.json", "utf-8"),
  ).abi;
  const packExtensions = generateExtensionFunctions(PackVRFDirectLogicABI);

  await setupPackVrf(permissionsExtensions, packExtensions);
  console.log("completed");
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
