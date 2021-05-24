async function main() {

  const [deployer] = await ethers.getSigners();

  console.log(
    "Deploying contracts with the account:",
    deployer.address
  );
  
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const PackToken_Factory = await ethers.getContractFactory("Pack");
  const packToken = await PackToken_Factory.deploy();

  console.log("Pack ERC1155 token address:", packToken.address);

  const PackMarket_Factory = await ethers.getContractFactory("PackMarket");
  const packMarket = await PackMarket_Factory.deploy(packToken.address);

  console.log("Pack Market address:", packMarket.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

// Pack ERC1155 token address (Rinkeby) -- 0xac063C80a70725e3c63FaaC04a10920596cd9255
// Pack Market address -- 0xD669F0c9C6A2E42DF4D10C799e4afCb2C8609c79