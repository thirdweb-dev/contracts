import hre, { run, ethers } from "hardhat";
import { Contract, ContractFactory, Bytes } from "ethers";

import addresses from "../../utils/address.json";
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

  console.log(`Deploying contracts with account: ${await deployer.getAddress()} to: ${networkName}`);

  // Get chain specific values
  const curentNetworkAddreses = addresses[networkName as keyof typeof addresses];
  const { protocolControl: protocolControlAddr, forwarder: forwarderAddr } = curentNetworkAddreses;
  const txOption = txOptions[networkName as keyof typeof txOptions];
  const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars[networkName as keyof typeof chainlinkVars];

  // Deploy Pack.sol
  const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
  const pack: Contract = await Pack_Factory.deploy(
    protocolControlAddr,
    "$PACK Protocol",
    vrfCoordinator,
    linkTokenAddress,
    keyHash,
    fees,
    forwarderAddr,
    txOption,
  );

  console.log("Pack.sol deployed at: ", pack.address);

  // Update module in `ProtocolControl`
  const protocolControl: Contract = await ethers.getContractAt("ProtocolControl", protocolControlAddr);

  const moduleId: Bytes = await protocolControl.PACK();
  const updateTx = await protocolControl.updateModule(moduleId, pack.address, txOption);

  console.log("Updating PACK module in ProtocolControl: ", updateTx.hash);

  await updateTx.wait();

  // Update contract addresses in `/utils`
  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...curentNetworkAddreses,

      pack: pack.address,
    },
  };

  fs.writeFileSync(path.join(__dirname, "../../utils/address.json"), JSON.stringify(updatedAddresses));
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
