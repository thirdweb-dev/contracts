import "dotenv/config";
import {
  ThirdwebSDK,
  computeCloneFactoryAddress,
  deployContractDeterministic,
  deployCreate2Factory,
  deployWithThrowawayDeployer,
  fetchAndCacheDeployMetadata,
  getCreate2FactoryAddress,
  getDeploymentInfo,
  getThirdwebContractAddress,
  isContractDeployed,
  resolveAddress,
} from "@thirdweb-dev/sdk";
import { Signer } from "ethers";
import { apiMap, chainIdApiKey, contractsToDeploy } from "./constants";

////// To run this script: `npx ts-node scripts/deploy-prebuilt-deterministic/bootstrap-on-a-chain.ts` //////
///// MAKE SURE TO PUT IN THE RIGHT CONTRACT NAME HERE AFTER PUBLISHING IT /////
//// THE CONTRACT SHOULD BE PUBLISHED WITH THE NEW PUBLISH FLOW ////

const publisherKey: string = process.env.THIRDWEB_PUBLISHER_PRIVATE_KEY as string;
const deployerKey: string = process.env.PRIVATE_KEY as string;

const polygonSDK = ThirdwebSDK.fromPrivateKey(publisherKey, "polygon");

const chainId = "8453"; // update here
const networkName = "base"; // update here

async function main() {
  const publisher = await polygonSDK.wallet.getAddress();

  const sdk = ThirdwebSDK.fromPrivateKey(deployerKey, chainId); // can also hardcode the chain here
  const signer = sdk.getSigner() as Signer;

  console.log("balance: ", await sdk.wallet.balance());

  // Deploy CREATE2 factory (if not already exists)
  const create2FactoryAddress = await getCreate2FactoryAddress(sdk.getProvider());
  if (await isContractDeployed(create2FactoryAddress, sdk.getProvider())) {
    console.log(`-- Create2 factory already present at ${create2FactoryAddress}\n`);
  } else {
    console.log(`-- Deploying Create2 factory at ${create2FactoryAddress}\n`);
    await deployCreate2Factory(signer, {});
  }

  // TWStatelessFactory (Clone factory)
  const cloneFactoryAddress = await computeCloneFactoryAddress(sdk.getProvider(), sdk.storage, create2FactoryAddress);
  if (await isContractDeployed(cloneFactoryAddress, sdk.getProvider())) {
    console.log(`-- TWCloneFactory present at ${cloneFactoryAddress}\n`);
  }

  for (const publishedContractName of contractsToDeploy) {
    const latest = await polygonSDK.getPublisher().getLatest(publisher, publishedContractName);

    if (latest && latest.metadataUri) {
      const { extendedMetadata } = await fetchAndCacheDeployMetadata(latest?.metadataUri, polygonSDK.storage);

      const isNetworkEnabled =
        extendedMetadata?.networksForDeployment?.networksEnabled.includes(parseInt(chainId)) ||
        extendedMetadata?.networksForDeployment?.allNetworks;

      if (extendedMetadata?.networksForDeployment && !isNetworkEnabled) {
        console.log(`Deployment of ${publishedContractName} disabled on ${networkName}\n`);
        continue;
      }

      console.log(`Deploying ${publishedContractName} on ${networkName}`);

      // const chainId = (await sdk.getProvider().getNetwork()).chainId;

      try {
        const implAddr = await getThirdwebContractAddress(publishedContractName, parseInt(chainId), sdk.storage);
        if (implAddr) {
          console.log(`implementation ${implAddr} already deployed on chainId: ${chainId}`);
          console.log();
          continue;
        }
      } catch (error) {}

      try {
        // any evm deployment flow

        // get deployment info for any evm
        const deploymentInfo = await getDeploymentInfo(
          latest.metadataUri,
          sdk.storage,
          sdk.getProvider(),
          create2FactoryAddress,
        );

        const implementationAddress = deploymentInfo.find(i => i.type === "implementation")?.transaction
          .predictedAddress as string;

        const isDeployed = await isContractDeployed(implementationAddress, sdk.getProvider());
        if (isDeployed) {
          console.log(`implementation ${implementationAddress} already deployed on chainId: ${chainId}`);
          console.log();
          continue;
        }

        console.log("Deploying as", await signer?.getAddress());
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
        if (transactionsForThrowawayDeployer.length > 0) {
          console.log("-- Deploying Infra");
          await deployWithThrowawayDeployer(signer, transactionsForThrowawayDeployer, {});
        }

        const resolvedImplementationAddress = await resolveAddress(implementationAddress);

        console.log(`-- Deploying ${publishedContractName} at ${resolvedImplementationAddress}`);
        // send each transaction directly to Create2 factory
        // process txns one at a time
        for (const tx of transactionsforDirectDeploy) {
          try {
            await deployContractDeterministic(signer, tx, {});
          } catch (e) {
            console.debug(`Error deploying contract at ${tx.predictedAddress}`, (e as any)?.message);
          }
        }
        console.log();
      } catch (e) {
        console.log("Error while deploying: ", e);
        console.log();
        continue;
      }
    } else {
      console.log("No previous release found");
      return;
    }
  }

  console.log("Deployments done.");
  console.log();

  console.log("---------- Verification ---------");
  console.log();
  for (const publishedContractName of contractsToDeploy) {
    try {
      await sdk.verifier.verifyThirdwebContract(
        publishedContractName,
        apiMap[parseInt(chainId)],
        chainIdApiKey[parseInt(chainId)] as string,
      );
      console.log();
    } catch (error) {
      console.log(error);
      console.log();
    }
  }

  console.log("All done.");
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
