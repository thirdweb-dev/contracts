import "dotenv/config";
import {
  ThirdwebSDK,
  computeCloneFactoryAddress,
  deployContractDeterministic,
  deployCreate2Factory,
  deployWithThrowawayDeployer,
  getDeploymentInfo,
  getThirdwebContractAddress,
  resolveAddress,
} from "@thirdweb-dev/sdk";
import { Signer } from "ethers";
import { chainIdApiKey, chainIdToName, getExplorerApiUrl } from "./constants";

const targetNetworkName = process.argv[2] as string;
if (!targetNetworkName) {
  console.log("Provide network name");
  process.exit(1);
}

let targetNetworkId: string = "";
for (const chainId of Object.keys(chainIdToName)) {
  if (chainIdToName[parseInt(chainId) as number] === targetNetworkName) {
    targetNetworkId = chainId;
  }
}

if (!targetNetworkId) {
  console.log("Invalid network");
  process.exit(1);
}

////// To run this script: `npx ts-node scripts/deploy-new-flow/deploy-new-flow-std-chains.ts` //////
///// MAKE SURE TO PUT IN THE RIGHT CONTRACT NAME HERE AFTER PUBLISHING IT /////
//// THE CONTRACT SHOULD BE PUBLISHED WITH THE NEW PUBLISH FLOW ////
const publishedContractName = "Multiwrap";
const privateKey: string = process.env.DEPLOYER_KEY as string; // should be the correct deployer key

const polygonSDK = ThirdwebSDK.fromPrivateKey(privateKey, "polygon");

async function main() {
  const publisher = await polygonSDK.wallet.getAddress();
  const latest = await polygonSDK.getPublisher().getLatest(publisher, publishedContractName);

  if (latest && latest.metadataUri) {
    const sdk = ThirdwebSDK.fromPrivateKey(privateKey, targetNetworkId); // can also hardcode the chain here
    const signer = sdk.getSigner() as Signer;
    const chainId = (await sdk.getProvider().getNetwork()).chainId;

    try {
      const implAddr = await getThirdwebContractAddress(publishedContractName, chainId, sdk.storage);
      if (implAddr) {
        console.log(`implementation ${implAddr} already deployed on chainId: ${chainId}`);
        process.exit(0);
      }
    } catch (e) {}

    console.log("Deploying as", signer?.getAddress());
    // any evm deployment flow

    // 1. Deploy CREATE2 factory (if not already exists)
    const create2Factory = await deployCreate2Factory(signer, {});

    // 2. get deployment info for any evm
    const deploymentInfo = await getDeploymentInfo(latest.metadataUri, sdk.storage, sdk.getProvider(), create2Factory);

    const implementationAddress = deploymentInfo.find(i => i.type === "implementation")?.transaction
      .predictedAddress as string;

    // 3. deploy infra + plugins + implementation using a throwaway Deployer contract

    // filter out already deployed contracts (data is empty)
    const transactionsToSend = deploymentInfo.filter(i => i.transaction.data && i.transaction.data.length > 0);
    const transactionsforDirectDeploy = transactionsToSend
      .filter(i => {
        return i.type !== "infra";
      })
      .map(i => i.transaction);
    const transactionsForThrowawayDeployer = transactionsToSend
      .filter(i => {
        return i.type === "infra";
      })
      .map(i => i.transaction);

    // deploy via throwaway deployer, multiple infra contracts in one transaction
    await deployWithThrowawayDeployer(signer, transactionsForThrowawayDeployer, {});

    // send each transaction directly to Create2 factory
    await Promise.all(
      transactionsforDirectDeploy.map(tx => {
        return deployContractDeterministic(signer, tx, {});
      }),
    );

    const resolvedImplementationAddress = await resolveAddress(implementationAddress);

    // 4. deploy proxy with TWStatelessFactory (Clone factory) and return address
    const cloneFactory = await computeCloneFactoryAddress(sdk.getProvider(), sdk.storage, create2Factory);

    console.log("Create2 Factory: ", create2Factory);
    console.log("Clone Factory: ", cloneFactory);
    console.log("Implementation: ", resolvedImplementationAddress);
    console.log();

    console.log("Verifying implementation");
    await sdk.verifier.verifyThirdwebContract(
      publishedContractName,
      getExplorerApiUrl(targetNetworkName),
      chainIdApiKey[chainId] as string,
    );
  } else {
    console.log("No previous release found");
    return;
  }

  console.log("All done.");
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
