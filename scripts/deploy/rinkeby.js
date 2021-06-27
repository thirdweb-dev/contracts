// UniswapV2 WETH-DAI Pair address on Rinkeby
const weth_dai_pair = "0x8B22F85d0c844Cf793690F6D9DFE9F11Ddb35449";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with account: ", deployer.address);

  // 1. Deploy control center `PackControl.sol`
  const PackControl_Factory = await ethers.getContractFactory("PackControl");
  let packControl = await PackControl_Factory.deploy();

  console.log("PackControl deployed at: ", packControl.address, " with no args");
  
  // 2. Deploy core module `PackERC1155.sol`
  const PackERC1155_Factory = await ethers.getContractFactory("PackERC1155");
  let packERC1155 = await PackERC1155_Factory.deploy(packControl.address);

  console.log("PackERC1155 deployed at: ", packERC1155.address, " with args: ", packControl.address);

  // 3.A. Deploy RNG contract
  const RNG_Factory = await ethers.getContractFactory("DexRNG");
  rng = await RNG_Factory.deploy();

  console.log("DexRNG deployed at: ", rng.address, " with no args");

  // 3.B. Add pair to DexRNG
  const addPairTx = await rng.addPair(weth_dai_pair);
  console.log("Adding pair to rng tx hash: ", addPairTx.hash);
  await addPairTx.wait()

  // 4. Initialize pack protocol with PackERC1155 and RNG  
  const initTx = await packControl.connect(deployer).initPackProtocol(packERC1155.address, rng.address);
  console.log("Initializing pack protocol tx hash: ", initTx.hash);
  await initTx.wait();

  // 5.A. Deploy module `Pack.sol`
  const PackHandler_Factory = await ethers.getContractFactory("PackHandler");
  let packHandler = await PackHandler_Factory.deploy(packERC1155.address);
  

  console.log("PackHandler deployed at: ", packHandler.address, " with args: ", packERC1155.address);

  // 5.B. Register `Pack` as a module in `PackControl`
  const packHandlerModuleName = "PACK_HANDLER";
  const addHandlerTx = await packControl.connect(deployer).addModule(packHandlerModuleName, packHandler.address);
  console.log("Adding PackHandler as module tx hash: ", addHandlerTx.wait());
  await addHandlerTx.wait()
  
  // 6.A. Deploy module `PackMarket.sol`
  const PackMarket_Factory = await ethers.getContractFactory("PackMarket");
  let packMarket = await PackMarket_Factory.deploy(packControl.address);

  console.log("PackMarket deployed at: ", packMarket.address, " with args: ", packControl.address);

  // 6.B. Register `PackMarket` as a module in `PackControl`
  const packMarketModuleName = "PACK_MARKET";
  const addMarketTx = await packControl.connect(deployer).addModule(packMarketModuleName, packMarket.address);
  console.log("Adding PackMarket as module tx hash: ", addMarketTx.hash);
  await addMarketTx.wait();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });