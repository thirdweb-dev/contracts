import hre, { run, ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";

import addresses from "../../utils/address.json";
import { txOptions } from "../../utils/txOptions";
import { chainlinkVars } from "../../utils/chainlink";

import ProtocolControlABI from "../../abi/ProtocolControl.json";
import PackABI from "../../abi/Pack.json";
import { bytecode } from "../../artifacts/contracts/ProtocolControl.sol/ProtocolControl.json";

import * as fs from "fs";
import * as path from "path";

enum ModuleType {
  Coin,
  NFT,
  Pack,
  Market,
  Other,
}

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
  const Pack_Factory: ContractFactory = new ethers.ContractFactory(PackABI, bytecode);
  const tx = await Pack_Factory.connect(deployer).deploy(
    protocolControlAddress,
    "$PACK Protocol", // This is supposed to be an `ipfs://...` type URI
    vrfCoordinator,
    linkTokenAddress,
    keyHash,
    fees,
    forwarderAddr,
    txOption,
  );

  console.log("Deploying Pack: ", tx.hash);

  await tx.wait();

  // Get deployed `Pack`'s address
  const packAddress = tx.address;

  // Get `ProtocolControl`
  const protocolControl: Contract = await ethers.getContractAt(ProtocolControlABI, protocolControlAddress);
  const addModuleTx = await protocolControl.addModule(packAddress, ModuleType.Pack);

  // Update contract addresses in `/utils`
  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...curentNetworkAddreses,

      pack: packAddress,
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
