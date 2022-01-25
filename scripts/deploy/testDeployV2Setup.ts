import hre, { ethers } from "hardhat";

// Contract types
import { TWFee } from "typechain/TWFee";
import { TWFactory } from "typechain/TWFactory";
import { DropERC721 } from "typechain/DropERC721";

// General Types
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber } from "ethers";
import { DropERC721__factory } from "typechain";

async function main() {
  const [deployer]: SignerWithAddress[] = await ethers.getSigners();

  // Constructor args
  const trustedForwarderAddress: string = "0xc82BbE41f2cF04e3a8efA18F7032BDD7f6d98a81";
  const defaultRoyaltyFeeBps: BigNumber = BigNumber.from(100); // 1 %
  const defaultTransactionFeeBps: BigNumber = BigNumber.from(50); // 0.5%
  const defaultRecipient: string = deployer.address;

  // Deploy CurrencyTransferLib
  const currencyTransferLib = await ethers.getContractFactory("CurrencyTransferLib").then(f => f.deploy());

  // Deploy TWFactory and TWRegistry
  const thirdwebFactory: TWFactory = await ethers
    .getContractFactory("TWFactory")
    .then(f => f.deploy(trustedForwarderAddress));
  const deployTxFactory = thirdwebFactory.deployTransaction;

  console.log("Deploying TWFactory and TWRegistry at tx: ", deployTxFactory.hash);

  await deployTxFactory.wait();

  const thirdwebRegistryAddr: string = await thirdwebFactory.registry();

  console.log("TWFactory address: ", thirdwebFactory.address);
  console.log("TWRegistry address: ", thirdwebRegistryAddr);

  // Deploy TWFee
  const thirdwebFee: TWFee = await ethers
    .getContractFactory("TWFee")
    .then(f =>
      f.deploy(
        trustedForwarderAddress,
        defaultRecipient,
        defaultRecipient,
        defaultRoyaltyFeeBps,
        defaultTransactionFeeBps,
      ),
    );
  const deployTxFee = thirdwebFee.deployTransaction;

  console.log("Deploying TWFee at tx: ", deployTxFee.hash);

  await deployTxFactory.wait();

  console.log("TWFee address: ", thirdwebFee.address);

  // Deploy a test implementation: Drop721
  const drop721Factory: DropERC721__factory = await ethers.getContractFactory("DropERC721", {
    libraries: {
      CurrencyTransferLib: currencyTransferLib.address,
    },
  });
  const drop721: DropERC721 = await drop721Factory.deploy(thirdwebFee.address);

  console.log("Deploying Drop721 at tx: ", drop721.deployTransaction.hash);

  await drop721.deployTransaction.wait();

  console.log("Drop721 address: ", drop721.address);

  // Set the deployed `Drop721` as an approved module in TWFactory
  const drop721ModuteType = await drop721.moduleType();
  const tx = await thirdwebFactory.addModuleImplementation(drop721ModuteType, drop721.address);

  console.log("Setting deployed Drop721 as an approved implementation at tx: ", tx.hash);
  await tx.wait();

  console.log("DONE. Now verifying contracts...");

  // Verify deployed contracts.
  await hre.run("verify:verify", {
    address: currencyTransferLib.address,
    constructorArguments: [],
  });
  await hre.run("verify:verify", {
    address: thirdwebFactory.address,
    constructorArguments: [trustedForwarderAddress],
  });
  await hre.run("verify:verify", {
    address: thirdwebRegistryAddr,
    constructorArguments: [thirdwebFactory.address, trustedForwarderAddress],
  });
  await hre.run("verify:verify", {
    address: thirdwebFee.address,
    constructorArguments: [
      trustedForwarderAddress,
      defaultRecipient,
      defaultRecipient,
      defaultRoyaltyFeeBps,
      defaultTransactionFeeBps,
    ],
  });
  await hre.run("verify:verify", {
    address: drop721.address,
    constructorArguments: [thirdwebFee.address],
  });
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });
