import hre, { run, ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";

import addresses from "../../utils/addresses/accesspacks.json";
import ModuleType from "../../utils/protocolModules";
import { txOptions } from "../../utils/txOptions";
import { chainlinkVars } from "../../utils/chainlink";

import * as fs from "fs";
import * as path from "path";

async function main() {
  await run("compile");

  console.log("\n");

  // Get signer
  const [deployer] = await ethers.getSigners();
  const networkName: string = hre.network.name.toLowerCase();

  // Get chain specific values
  const curentNetworkAddreses = addresses[networkName as keyof typeof addresses];
  const { protocolControl: protocolControlAddress, forwarder: forwarderAddr } = curentNetworkAddreses;
  const txOption = txOptions[networkName as keyof typeof txOptions];
  const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars[networkName as keyof typeof chainlinkVars];

  console.log(`Deploying contracts with account: ${await deployer.getAddress()} to ${networkName}`);

  // Deploy `Pack`
  const contractURI: string = "";
  const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
  const pack = await Pack_Factory.connect(deployer).deploy(
    protocolControlAddress,
    contractURI,
    vrfCoordinator,
    linkTokenAddress,
    keyHash,
    fees,
    forwarderAddr,
    txOption,
  );

  console.log(`Deploying Pack: ${pack.address} at tx hash: ${pack.deployTransaction.hash}`);

  await pack.deployed();

  // Get deployed `Pack`'s address
  const packAddress = pack.address;

  // Get `ProtocolControl`
  const protocolControl: Contract = await ethers.getContractAt("ProtocolControl", protocolControlAddress);
  const addModuleTx = await protocolControl.addModule(packAddress, ModuleType.Pack);
  await addModuleTx.wait();

  // Update contract addresses in `/utils`
  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...curentNetworkAddreses,

      pack: packAddress,
    },
  };

  fs.writeFileSync(path.join(__dirname, "../../utils/addresses/accesspacks.json"), JSON.stringify(updatedAddresses));
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
