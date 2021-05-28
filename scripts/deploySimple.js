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

// Pack ERC1155 token address (Rinkeby) -- 0x932a80d12133daDa78d1eFeAa69C53f35b7717eB
// Pack Market address -- 0xdF6D4D22918048bA57e849dBBc83d9Bb502bb150