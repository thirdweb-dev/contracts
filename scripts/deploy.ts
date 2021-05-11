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
  const PackCoinFactory: ContractFactory = await ethers.getContractFactory("PackCoin");
  const packCoinContract: Contract =
    ethers.provider?.network?.chainId === 31337
      ? await PackCoinFactory.deploy()
      : PackCoinFactory.attach("0x182e07Eb9e57f7eD4F67262CbDC63cAe62A475B0");
  console.log("Pack Coin Contract deployed to: ", packCoinContract.address);

  const PackFactory: ContractFactory = await ethers.getContractFactory("Pack");
  const packContract: Contract = await PackFactory.deploy();
  console.log("Pack Contract deployed to: ", packContract.address);

  const PackMarketFactory: ContractFactory = await ethers.getContractFactory("PackMarket");
  const packMarketContract: Contract = await PackMarketFactory.deploy(packContract.address);
  console.log("Pack Market Contract deployed to: ", packMarketContract.address);

  const signers: SignerWithAddress[] = await ethers.getSigners();
  const pc1a = await signers[1].getAddress();
  const pc2a = await signers[2].getAddress();
  console.log("wallet 0 contract:", await signers[0].getAddress());
  console.log("wallet 1:", pc1a);
  console.log("wallet 2:", pc2a);

  const pc1 = packContract.connect(signers[1]);
  const pc2 = packContract.connect(signers[2]);
  const pcc1 = packCoinContract.connect(signers[1]);
  const pcc2 = packCoinContract.connect(signers[2]);
  const pmc1 = packMarketContract.connect(signers[1]);
  const pmc2 = packMarketContract.connect(signers[2]);

  await packCoinContract.mint(pc1a, (10 * 10 ** 18).toString());
  await packCoinContract.mint(pc2a, (10 * 10 ** 18).toString());

  await pcc1.approve(packMarketContract.address, (100 * 10 ** 18).toString()); // todo: approve infinity
  await pcc2.approve(packMarketContract.address, (100 * 10 ** 18).toString()); // todo: approve infinity

  await pc1.createPack("pack0");
  await pc1.setApprovalForAll(packMarketContract.address, true);

  // TODO replace with notifications events
  if (ethers?.provider?.network.chainId !== 31337) {
    await new Promise(r => setTimeout(r, 30000));
  }

  await pmc1.sell(0, packCoinContract.address, (2 * 10 ** 18).toString());

  // TODO replace with notifications events
  if (ethers?.provider?.network.chainId !== 31337) {
    await new Promise(r => setTimeout(r, 30000));
  }

  await pmc2.buy(await signers[1].getAddress(), 0, 5);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
