import hre, { ethers } from "hardhat";

// Contract types
import { TWFee } from "typechain/TWFee";
import { TWFactory } from "typechain/TWFactory";

// General Types
import { DropERC721 } from "typechain/DropERC721";
import { DropERC1155 } from "typechain/DropERC1155";
import { TokenERC20 } from "typechain/TokenERC20";
import { TokenERC721 } from "typechain/TokenERC721";
import { TokenERC1155 } from "typechain/TokenERC1155";

async function main() {

  // // Constructor args
  // const trustedForwarderAddress: string = "0xc82BbE41f2cF04e3a8efA18F7032BDD7f6d98a81";

  // // Deploy CurrencyTransferLib
  // const currencyTransferLib = await ethers.getContractFactory("CurrencyTransferLib").then(f => f.deploy());
  // // Deploy FeeType
  // const feeTypeLib = await ethers.getContractFactory("FeeType").then(f => f.deploy());

  // const options = { gasPrice: ethers.utils.parseUnits("30", "gwei"), gasLimit: 7000000 };

  // // Deploy TWFactory and TWRegistry
  // const thirdwebFactory: TWFactory = await ethers
  //   .getContractFactory("TWFactory")
  //   .then(f => f.deploy(trustedForwarderAddress, options)) as TWFactory;
  // const deployTxFactory = thirdwebFactory.deployTransaction;

  // console.log("Deploying TWFactory and TWRegistry at tx: ", deployTxFactory.hash);

  // await deployTxFactory.wait();

  // const thirdwebRegistryAddr: string = await thirdwebFactory.registry();

  // console.log("TWFactory address: ", thirdwebFactory.address);
  // console.log("TWRegistry address: ", thirdwebRegistryAddr);

  // // Deploy TWFee
  // const thirdwebFee: TWFee = await ethers
  //   .getContractFactory("TWFee")
  //   .then(f =>
  //     f.deploy(
  //       trustedForwarderAddress,
  //       thirdwebFactory.address,
  //       options
  //     ),
  //   ) as TWFee;
  // const deployTxFee = thirdwebFee.deployTransaction;

  // console.log("Deploying TWFee at tx: ", deployTxFee.hash);

  // await deployTxFee.wait();

  // console.log("TWFee address: ", thirdwebFee.address);

  // // Deploy a test implementation: Drop721
  // const drop721Factory = await ethers.getContractFactory("DropERC721");
  // const drop721: DropERC721 = await drop721Factory.deploy(thirdwebFee.address, options) as DropERC721;

  // console.log("Deploying Drop721 at tx: ", drop721.deployTransaction.hash);

  // await drop721.deployTransaction.wait();

  // console.log("Drop721 address: ", drop721.address);

  // // Set the deployed `Drop721` as an approved module in TWFactory
  // const drop721ModuteType = await drop721.moduleType();
  // const tx1 = await thirdwebFactory.addModuleImplementation(drop721ModuteType, drop721.address, options);

  // console.log("Setting deployed Drop721 as an approved implementation at tx: ", tx1.hash);
  // await tx1.wait();

  // // Deploy a test implementation: Drop1155
  // const drop1155: DropERC1155 = await ethers.getContractFactory("DropERC1155").then(f => f.deploy(thirdwebFee.address, options)) as DropERC1155;

  // console.log("Deploying Drop1155 at tx: ", drop1155.deployTransaction.hash);

  // console.log("Drop1155 address: ", drop1155.address);

  // // Set the deployed `Drop721` as an approved module in TWFactory
  // const drop1155ModuteType = await drop1155.moduleType();
  // const tx2 = await thirdwebFactory.addModuleImplementation(drop1155ModuteType, drop1155.address, options);

  // console.log("Setting deployed Drop1155 as an approved implementation at tx: ", tx2.hash);
  // await tx2.wait();

  // // Deploy a test implementation: TokenERC20
  // const tokenERC20: TokenERC20 = await ethers.getContractFactory("TokenERC20").then(f => f.deploy(options)) as TokenERC20;
  // console.log("Deploying TokenERC20 at tx: ", tokenERC20.deployTransaction.hash);
  // console.log("TokenERC20 address: ", tokenERC20.address);

  // // Set the deployed `TokenERC20` as an approved module in TWFactory
  // const tokenERC20ModulteType = await tokenERC20.moduleType();
  // const tx3 = await thirdwebFactory.addModuleImplementation(tokenERC20ModulteType, tokenERC20.address, options);

  // console.log("Setting deployed TokenERC20 as an approved implementation at tx: ", tx3.hash);
  // await tx3.wait();

  // // Deploy a test implementation: TokenERC721
  // const tokenERC721: TokenERC721 = await ethers.getContractFactory("TokenERC721").then(f => f.deploy(thirdwebFee.address, options)) as TokenERC721;
  // console.log("Deploying TokenERC721 at tx: ", tokenERC721.deployTransaction.hash);
  // console.log("TokenERC721 address: ", tokenERC721.address);

  // // Set the deployed `TokenERC721` as an approved module in TWFactory
  // const tokenERC721ModulteType = await tokenERC721.moduleType();
  // const tx4 = await thirdwebFactory.addModuleImplementation(tokenERC721ModulteType, tokenERC721.address, options);

  // console.log("Setting deployed TokenERC721 as an approved implementation at tx: ", tx4.hash);
  // await tx4.wait();

  // // Deploy a test implementation: TokenERC1155
  // const tokenERC1155: TokenERC1155 = await ethers.getContractFactory("TokenERC1155").then(f => f.deploy(thirdwebFee.address, options)) as TokenERC1155;
  // console.log("Deploying TokenERC1155 at tx: ", tokenERC1155.deployTransaction.hash);
  // console.log("TokenERC1155 address: ", tokenERC1155.address);

  // // Set the deployed `TokenERC1155` as an approved module in TWFactory
  // const tokenERC1155ModulteType = await tokenERC1155.moduleType();
  // const tx5 = await thirdwebFactory.addModuleImplementation(tokenERC1155ModulteType, tokenERC1155.address, options);

  // console.log("Setting deployed TokenERC1155 as an approved implementation at tx: ", tx5.hash);
  // await tx5.wait();

  // console.log("DONE. Now verifying contracts...");

  // // Verify deployed contracts.
  // await hre.run("verify:verify", {
  //   address: currencyTransferLib.address,
  //   constructorArguments: [],
  // });
  // await hre.run("verify:verify", {
  //   address: thirdwebFactory.address,
  //   constructorArguments: [trustedForwarderAddress],
  // });
  // await hre.run("verify:verify", {
  //   address: thirdwebRegistryAddr,
  //   constructorArguments: [thirdwebFactory.address, trustedForwarderAddress],
  // });
  // await hre.run("verify:verify", {
  //   address: thirdwebFee.address,
  //   constructorArguments: [
  //     trustedForwarderAddress,
  //     thirdwebFactory.address
  //   ],
  // });
  // await hre.run("verify:verify", {
  //   address: drop721.address,
  //   constructorArguments: [thirdwebFee.address],
  // });

  // await hre.run("verify:verify", {
  //   address: "0xC966c8E15c104515A49F91C58DCcc65CC5a2CBA5",
  //   constructorArguments: ["0xc82BbE41f2cF04e3a8efA18F7032BDD7f6d98a81"],
  // });
  // await hre.run("verify:verify", {
  //   address: "0xC6642e134E61A1888B9ff1f61E8003b9160c4e01",
  //   constructorArguments: ["0xc82BbE41f2cF04e3a8efA18F7032BDD7f6d98a81"],
  // });
  // await hre.run("verify:verify", {
  //   address: "0xb927Bd28777cEa8D34c07000c587A4ea5a8c53D0",
  //   constructorArguments: [
  //     "0xc82BbE41f2cF04e3a8efA18F7032BDD7f6d98a81",
  //     "0xC966c8E15c104515A49F91C58DCcc65CC5a2CBA5"
  //   ],
  // });
  // await hre.run("verify:verify", {
  //   address: "0xd1d75C1E62a1084F59e54790FD9DEa1E717eba17",
  //   constructorArguments: ["0xb927Bd28777cEa8D34c07000c587A4ea5a8c53D0"],
  // });
  // await hre.run("verify:verify", {
  //   address: "0x0338736238Fd57D5fC6D5f9d2651e72b8641e359",
  //   constructorArguments: ["0xb927Bd28777cEa8D34c07000c587A4ea5a8c53D0"],
  // });
  // await hre.run("verify:verify", {
  //   address: "0x8C9ad209f077925F7893C360a5D85a086140143b",
  //   constructorArguments: [],
  // });
  await hre.run("verify:verify", {
    address: "0xC43939C31d90937472F3e6F5bB91ae7A21E1D1D1",
    constructorArguments: ["0xb927Bd28777cEa8D34c07000c587A4ea5a8c53D0"],
  });
  await hre.run("verify:verify", {
    address: "0x9D69A7D0DF849DA24A8524576eA95E13Ae77CFF7",
    constructorArguments: ["0xb927Bd28777cEa8D34c07000c587A4ea5a8c53D0"],
  });
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
