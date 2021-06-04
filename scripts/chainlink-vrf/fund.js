require('dotenv').config();
const { ethers } = require("ethers");

// Get LINK token ABI
const { abi } = require('../../artifacts/@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol/LinkTokenInterface.json');

// Set up wallet.
const privateKey = process.env.TEST_PRIVATE_KEY;
const alchemyEndpoint = process.env.ALCHEMY_ENDPOINT;

const provider = new ethers.providers.JsonRpcProvider(alchemyEndpoint, 'rinkeby');
const wallet = new ethers.Wallet(privateKey, provider)

// Get LINK contract
const linkTokenAddress = '0x01be23585060835e02b77ef475b0cc51aa1e0709'
const linkContract = new ethers.Contract(linkTokenAddress, abi, wallet);

const packTokenAddress = '0x6416795AF11336ef33EF7BAd1354F370141f8728';

const to = packTokenAddress;
const value = ethers.utils.parseEther('10');

async function main() {
  const transferTx = await linkContract.transfer(to, value);
  await transferTx.wait();

  console.log('Transfer tx hash', transferTx.hash);
}

// async function main() {
//   const balance = await linkContract.balanceOf(wallet.address);

//   console.log('Balance:', ethers.utils.formatEther(balance.toString()));
// }

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });