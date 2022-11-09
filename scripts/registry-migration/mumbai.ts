import { count } from "console";
import { BytesLike, PopulatedTransaction } from "ethers";
import fs from "fs";
import { ethers } from "hardhat";
import { TWRegistry } from "typechain";
import { AddedEvent, AddedEventFilter } from "typechain/contracts/TWMultichainRegistry";

const getEvents = async (
  twRegistry: TWRegistry,
  eventFilter: AddedEventFilter,
  start: number,
  end: number,
): Promise<AddedEvent[]> => {
  if (start > end) {
    return [];
  } else {
    try {
      let events = await twRegistry.queryFilter(eventFilter, start, end);
      console.log("returning try: ", events.length);
      return events;
    } catch (error) {
      console.log("catch 1: ", start, Math.floor((start + end) / 2));
      console.log("catch 2: ", Math.floor((start + end) / 2) + 1, end);
      console.log();
      return (await getEvents(twRegistry, eventFilter, start, Math.floor((start + end) / 2))).concat(
        await getEvents(twRegistry, eventFilter, Math.floor((start + end) / 2) + 1, end),
      );
    }
  }
};

async function main() {
  const twRegistryAddress: string = "0x7c487845f98938Bb955B1D5AD069d9a30e4131fd"; // replace
  const twRegistry: TWRegistry = await ethers.getContractAt("TWRegistry", twRegistryAddress);

  const block = await ethers.provider.getBlockNumber();
  console.log("block ", block);

  // get `Added` data
  let eventFilter = twRegistry.filters.Added(null, null);
  let totalEvents = await getEvents(twRegistry, eventFilter, 0, block);
  let addedDeployments = totalEvents.map(item => {
    return {
      deployer: item.args.deployer,
      deployment: item.args.deployment,
    };
  });

  // get `Removed` data
  eventFilter = twRegistry.filters.Deleted(null, null);
  totalEvents = await getEvents(twRegistry, eventFilter, 7500000, block);
  let removedDeployments = totalEvents.map(item => {
    return {
      deployer: item.args.deployer,
      deployment: item.args.deployment,
    };
  });

  let countAdded: any = {};
  addedDeployments.forEach(item => {
    const deployString = item.deployer.concat(item.deployment);
    return countAdded[deployString] >= 1 ? (countAdded[deployString] += 1) : (countAdded[deployString] = 1);
  });
  console.log(countAdded);
  console.log();

  let countRemoved: any = {};
  removedDeployments.forEach(item => {
    const deployString = item.deployer.concat(item.deployment);
    return countRemoved[deployString] >= 1 ? (countRemoved[deployString] += 1) : (countRemoved[deployString] = 1);
  });
  console.log(countRemoved);
  console.log();

  // filter unique deployments still added on registry
  let checked: any = {};
  let uniqueDeployers = addedDeployments.filter(item => {
    const deployString = item.deployer.concat(item.deployment);
    if (checked[deployString]) {
      return false;
    } else {
      checked[deployString] = true;
      if (countRemoved[deployString]) {
        return countAdded[deployString] > countRemoved[deployString];
      }
      return true;
    }
  });

  // append to existing migration data
  let migrationData = JSON.parse(fs.readFileSync("./scripts/registry-migration/migration-data.json", "utf-8"));

  let uniqueDeployersWithChainId = uniqueDeployers.map(item => {
    return {
      chainId: ethers.provider.network.chainId,
      ...item,
    };
  });

  migrationData.push(...uniqueDeployersWithChainId);

  fs.writeFileSync("./scripts/registry-migration/migration-data.json", JSON.stringify(migrationData), "utf-8");

  console.log(migrationData);
  console.log("unique deployers length: ", uniqueDeployers.length);
  console.log("migration data length: ", migrationData.length);

  //   console.log(totalEvents.length);
  //   console.log("sample: ", totalEvents[1]);
  //   console.log("sample deployer: ", totalDeployers[1]);
  //   console.log("total deployers: ", totalDeployers.length);
  //   console.log("unique deployers: ", uniqueDeployers.length);

  //   console.log("getting all deployments now");
  //   let txns: any[] = [];
  //   for (let i = 0; i < 1; i++) {
  //     const txData = await twRegistry.populateTransaction.getAll(uniqueDeployers[i]);
  //     console.log("populated tx: ", txData.data);
  //     txns.push(txData.data);
  //     const deploymentAddresses: any = await twRegistry.multicall(txns);
  //     console.log("count of addresses for deployer 0: ", deploymentAddresses);
  //   }

  //   let deployments: string[] = await twRegistry.getAll(uniqueDeployers[1]);
  //   console.log("total deployments of deployer-1: ", deployments);
  //   console.log("count: ", deployments.length);

  console.log("Done.");
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
