import { Contract, ContractFactory } from "ethers";
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";

async function main(): Promise<void> {
  // Hardhat always runs the compile task when running scripts through it.
  // If this runs in a standalone fashion you may want to call compile manually
  // to make sure everything is compiled
  // await run("compile");

  // We get the contract to deploy
  //const Greeter: ContractFactory = await ethers.getContractFactory("Greeter");
  //const greeter: Contract = await Greeter.deploy("Hello, Buidler!");
  //await greeter.deployed();
  const PackFactory: ContractFactory = await ethers.getContractFactory("Pack");
  const packContract: Contract = await PackFactory.deploy();
  console.log("Pack Contract deployed to: ", packContract.address);

  const PackMarketFactory: ContractFactory = await ethers.getContractFactory("PackMarket");
  const packMarketContract: Contract = await PackMarketFactory.deploy(packContract.address);
  console.log("Pack Market Contract deployed to: ", packMarketContract.address);

  const signers: SignerWithAddress[] = await ethers.getSigners();
  const pc1 = packContract.connect(signers[1]);
  const pc2 = packContract.connect(signers[2]);
  const pmc1 = packMarketContract.connect(signers[1]);
  const pmc2 = packMarketContract.connect(signers[2]);

  await pc1.createPack("pack0");
  await pc1.setApprovalForAll(packMarketContract.address, true);
  await pmc1.sell(0, 5);
  await pmc2.buy(0, 5);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
