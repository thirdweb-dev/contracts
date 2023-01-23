import { ethers } from "hardhat";

////// To run this script: `npx hardhat run scripts/thirdweb_wallet/setup.ts --network goerli` //////

async function main() {

    const accountImpl = await ethers.getContractFactory("Account").then(f => f.deploy());
    console.log("Account implementation address: ", accountImpl.address);
    await accountImpl.deployTransaction.wait()
    
    const accountAdminImpl = await ethers.getContractFactory("AccountAdmin").then(f => f.deploy(accountImpl.address));
    console.log("AccountAdmin implementation address: ", accountAdminImpl.address);
    await accountAdminImpl.deployTransaction.wait();

    const trustedForwarders = ["0x5001A14CA6163143316a7C614e30e6041033Ac20"]; // Goerli forwarder

    const accountAdmin = await ethers.getContractFactory("TWProxy").then(f => f.deploy(
        accountAdminImpl.address,
        accountAdminImpl.interface.encodeFunctionData("initialize", [trustedForwarders])
    ));
    console.log("AccountAdmin deployment address: ", accountAdmin.address);
    await accountAdmin.deployTransaction.wait();
}

main()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });