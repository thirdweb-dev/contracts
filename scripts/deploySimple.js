// Chainlink info for Rinkeby

const vrfCoordinator = process.env.CHAINLINK_VRF_COORDINATOR;
const linkTokenAddress = process.env.CHAINLINK_LINK_TOKEN;
const keyHash = process.env.CHAINLINK_KEY_HASH;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const PackToken_Factory = await ethers.getContractFactory("Pack");
  const packToken = await PackToken_Factory.deploy(vrfCoordinator, linkTokenAddress, keyHash);

  console.log("Pack token address:", packToken.address);

  const PackMarket_Factory = await ethers.getContractFactory("PackMarket");
  const packMarket = await PackMarket_Factory.deploy(packToken.address);

  console.log("PackMarket token address:", packMarket.address);

  //  const PackCoin_Factory = await ethers.getContractFactory("PackCoin");
  //const packCoin = await PackCoin_Factory.deploy();

  //console.log("PackCoin token address:", packCoin.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

// Pack ERC1155 token address (Rinkeby) -- 0x07ab3E15fCA0e4a02176f71Fe7fc60fb46A3E4A1
// Pack Market address -- 0x741d2eF63d1b1646BAef2EC01b8605a23Dc2d4E4
