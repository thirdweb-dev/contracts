  
// Chainlink info for Rinkeby

const vrfCoordinator = '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B'
const linkTokenAddress = '0x01be23585060835e02b77ef475b0cc51aa1e0709'
const keyHash = '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311'

async function main() {

  const [deployer] = await ethers.getSigners();

  console.log(
    "Deploying contracts with the account:",
    deployer.address
  );
  
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const PackToken_Factory = await ethers.getContractFactory("Pack");
  const packToken = await PackToken_Factory.deploy(vrfCoordinator, linkTokenAddress, keyHash);

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

// Pack ERC1155 token address (Rinkeby) -- 0x0c56B393043CDA7c726c27FdD64Bd9262428515F
// Pack Market address (Rinkeby) -- 0x24574D0C177ad9E5cD74d9dBF5a9A729924e72e2