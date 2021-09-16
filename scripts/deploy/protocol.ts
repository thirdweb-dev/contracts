import hre, { run, ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import addresses from "../../utils/address.json";
import { txOptions } from "../../utils/txOptions";
import { chainlinkVars } from "../../utils/chainlink";

import * as fs from "fs";
import * as path from "path";

async function main() {
  await run("compile");

  console.log("\n");

  // Get signer and chainId.
  const [deployer]: SignerWithAddress[] = await ethers.getSigners();
  const networkName: string = hre.network.name.toLowerCase();

  console.log(`Deploying contracts with account: ${await deployer.getAddress()} to: ${networkName}`);

  // Get chain specific values
  const curentNetworkAddreses = addresses[networkName as keyof typeof addresses];
  const { forwarder: forwarderAddr } = curentNetworkAddreses;
  const txOption = txOptions[networkName as keyof typeof txOptions];
  const { vrfCoordinator, linkTokenAddress, keyHash, fees } = chainlinkVars[networkName as keyof typeof chainlinkVars];

  let forwarderAddress = forwarderAddr;

  // Deploy `Forwarder.sol` if it isn't deployed already.
  if (!forwarderAddress) {
    
    const minimalForwarder_factory: ContractFactory = await ethers.getContractFactory("Forwarder");
    const minimalForwarder: Contract = await minimalForwarder_factory.deploy(txOption);

    console.log("Deployed MinimalForwarder at: ", minimalForwarder.address);

    await minimalForwarder.deployTransaction.wait();

    forwarderAddress = minimalForwarder.address;
  }

  // Deploy ProtocolControl
  const ProtocolControl_Factory: ContractFactory = await ethers.getContractFactory("ProtocolControl");
  const protocolControl: Contract = await ProtocolControl_Factory.deploy(txOption);

  console.log("ProtocolControl.sol deployed at: ", protocolControl.address);

  await protocolControl.deployTransaction.wait();

  // Deploy Pack
  const Pack_Factory: ContractFactory = await ethers.getContractFactory("Pack");
  const pack: Contract = await Pack_Factory.deploy(
    protocolControl.address,
    "$PACK Protocol",
    vrfCoordinator,
    linkTokenAddress,
    keyHash,
    fees,
    forwarderAddress,
    txOption,
  );

  console.log("Pack.sol is deployed at: ", pack.address);

  await pack.deployTransaction.wait();

  // Deploy Market
  const Market_Factory: ContractFactory = await ethers.getContractFactory("Market");
  const market: Contract = await Market_Factory.deploy(protocolControl.address, forwarderAddress, txOption);

  console.log("Market.sol is deployed at: ", market.address);

  await market.deployTransaction.wait();

  // Initialize protocol
  const initTx = await protocolControl.initializeProtocol(pack.address, market.address, txOption);

  console.log("Initializing protocol: ", initTx.hash);

  await initTx.wait();

  // Update contract addresses in `/utils`
  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...curentNetworkAddreses,

      protocolControl: protocolControl.address,
      pack: pack.address,
      market: market.address,
      forwarder: forwarderAddress,
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
