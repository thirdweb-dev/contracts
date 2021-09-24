import hre, { run, ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";

import addresses from "../../utils/address.json";
import { txOptions } from "../../utils/txOptions";

import ProtocolControlABI from "../../abi/ProtocolControl.json";
import RegistryABI from "../../abi/Registry.json";
import CoinABI from "../../abi/Coin.json";
import { bytecode } from "../../artifacts/contracts/Coin.sol/Coin.json";
import ModuleType from "../../utils/protocolModules";

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
  const { protocolControl: protocolControlAddress, registry: registryAddress } = curentNetworkAddreses;
  const txOption = txOptions[networkName as keyof typeof txOptions];

  console.log(`Deploying contracts with account: ${await deployer.getAddress()} to ${networkName}`);

  // Get Forwarder from registry
  const registry: Contract = await ethers.getContractAt(RegistryABI, registryAddress);
  const forwarderAddr: string = await registry.forwarder();

  // Deploy `Coin`
  const name: string = "Coin name e.g. Chainlink token";
  const symbol: string = "e.g. LINK";

  const Coin_Factory: ContractFactory = new ethers.ContractFactory(CoinABI, bytecode);
  const contractURI: string = "ipfs://QmYMgpVGBgVZunM2uDPnobsHpryMmkXF8ZPJGiHfLpwShS";
  const tx = await Coin_Factory.connect(deployer).deploy(
    protocolControlAddress,
    name,
    symbol,
    forwarderAddr,
    contractURI,
    txOption,
  );

  console.log("Deploying Nft: ", tx.hash);
  console.log(tx.address, protocolControlAddress, name, symbol, forwarderAddr, contractURI);

  await tx.deployed();

  // Get deployed `Coin`'s address
  const coinAddress = tx.address;

  // Get `ProtocolControl`
  const protocolControl: Contract = await ethers.getContractAt(ProtocolControlABI, protocolControlAddress);
  const addModuleTx = await protocolControl.addModule(coinAddress, ModuleType.Coin);
  await addModuleTx.wait();

  // Update contract addresses in `/utils`
  const updatedAddresses = {
    ...addresses,

    [networkName]: {
      ...curentNetworkAddreses,

      coin: coinAddress,
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
