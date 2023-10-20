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
import { DEFAULT_CHAINS, apiMap, chainIdApiKey } from "./constants";

////// To run this script: `npx ts-node scripts/deploy-prebuilt-deterministic/deploy-deterministic-std-chains.ts` //////
///// MAKE SURE TO PUT IN THE RIGHT CONTRACT NAME HERE AFTER PUBLISHING IT /////
//// THE CONTRACT SHOULD BE PUBLISHED WITH THE NEW PUBLISH FLOW ////
const publishedContractName = "MarketplaceV3";
const publisherAddress: string = "deployer.thirdweb.eth";
const deployerKey: string = process.env.PRIVATE_KEY as string;
const secretKey: string = process.env.THIRDWEB_SECRET_KEY as string;

const polygonSDK = new ThirdwebSDK("polygon", { secretKey });

async function main() {
  const latest = await polygonSDK.getPublisher().getLatest(publisherAddress, publishedContractName);

  if (latest && latest.metadataUri) {
    const { extendedMetadata } = await fetchAndCacheDeployMetadata(latest?.metadataUri, polygonSDK.storage);

    for (const chain of DEFAULT_CHAINS) {
      const isNetworkEnabled =
        extendedMetadata?.networksForDeployment?.networksEnabled.includes(chain.chainId) ||
        extendedMetadata?.networksForDeployment?.allNetworks;

      if (extendedMetadata?.networksForDeployment && !isNetworkEnabled) {
        console.log(`Deployment of ${publishedContractName} disabled on ${chain.slug}\n`);
        continue;
      }

      console.log(`Deploying ${publishedContractName} on ${chain.slug}`);
      const sdk = ThirdwebSDK.fromPrivateKey(deployerKey, chain, { secretKey }); // can also hardcode the chain here
      const signer = sdk.getSigner() as Signer;
      // const chainId = (await sdk.getProvider().getNetwork()).chainId;

      try {
        const implAddr = await getThirdwebContractAddress(
          publishedContractName,
          chain.chainId,
          sdk.storage,
          "latest",
          sdk.options.clientId,
          sdk.options.secretKey,
        );
        if (implAddr) {
          console.log(`implementation ${implAddr} already deployed on chainId: ${chain.slug}`);
          console.log();
          continue;
        }
      } catch (error) {
        // no-op
      }

      try {
        console.log("Deploying as", await sdk.wallet.getAddress());
        console.log("Balance", await sdk.wallet.balance().then(b => b.displayValue));
        // any evm deployment flow

        // Deploy CREATE2 factory (if not already exists)
        const create2FactoryAddress = await getCreate2FactoryAddress(sdk.getProvider());
        if (await isContractDeployed(create2FactoryAddress, sdk.getProvider())) {
          console.log(`-- Create2 factory already present at ${create2FactoryAddress}`);
        } else {
          console.log(`-- Deploying Create2 factory at ${create2FactoryAddress}`);
          await deployCreate2Factory(signer, {});
        }

        // TWStatelessFactory (Clone factory)
        const cloneFactoryAddress = await computeCloneFactoryAddress(
          sdk.getProvider(),
          sdk.storage,
          create2FactoryAddress,
          sdk.options.clientId,
          sdk.options.secretKey,
        );
        if (await isContractDeployed(cloneFactoryAddress, sdk.getProvider())) {
          console.log(`-- TWCloneFactory already present at ${cloneFactoryAddress}`);
        }

        // get deployment info for any evm
        const deploymentInfo = await getDeploymentInfo(
          latest.metadataUri,
          sdk.storage,
          sdk.getProvider(),
          create2FactoryAddress,
          sdk.options.clientId,
          sdk.options.secretKey,
        );

        const implementationAddress = deploymentInfo.find(i => i.type === "implementation")?.transaction
          .predictedAddress as string;

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
    }

    console.log("Deployments done.");
    console.log();
    console.log("---------- Verification ---------");
    console.log();
    for (const chain of DEFAULT_CHAINS) {
      const sdk = new ThirdwebSDK(chain, {
        secretKey,
      });
      console.log("Verifying on: ", chain.slug);
      try {
        await sdk.verifier.verifyThirdwebContract(
          publishedContractName,
          apiMap[chain.chainId],
          chainIdApiKey[chain.chainId] as string,
        );
        console.log();
      } catch (error) {
        console.log(error);
        console.log();
      }
    }
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
