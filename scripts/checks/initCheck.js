require('dotenv').config()
const { ethers } = require('ethers');

const { getContract, ADDRESS } = require('../contractUtils')


async function main() {
  
  // Get contracts
  const packControl = getContract("PackControl", "rinkeby");
  const packERC1155 = getContract("PackERC1155", "rinkeby");

  // require -- `initPackProtocol` has been called on packControl
  const packERC1155_module_address = await packControl.getModule("PACK_ERC1155");
  const rng_module_address = await packControl.getModule("PACK_RNG");

  if(packERC1155_module_address != ADDRESS["PackERC1155"] || rng_module_address != ADDRESS["DexRNG"]) {
    
    throw new Error(
      `'initPackProtocol' has not been called with the correct addresses, or not called at all. \n
        Retreived address PackERC1155: ${packERC1155_module_address} RNG: ${rng_module_address}`
    );
  } else {
    console.log("'initPackProtocol' has been called on PackControl.sol");
  }

  // require -- PackHandler and PackMarket are modules
  const packHandler_module_address = await packControl.getModule("PACK_HANDLER");
  const packMaket_module_address = await packControl.getModule("PACK_MARKET");

  if(packHandler_module_address != ADDRESS["PackHandler"] || packMaket_module_address != ADDRESS["PackMarket"]) {
    
    throw new Error(
      `Handler and Market modules have not been set correctly. \n
        Retreived address PackHandler: ${packHandler_module_address} PackMarket: ${packMaket_module_address}`
    );
  } else {
    console.log("Handler and Market modules have been set correctly.");
  }

  // require -- PackHandler has MINTER ROLE in PackERC1155
  const MINTER_ROLE = ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes("MINTER_ROLE")
  )
  const handlerHasMinterRole = await packERC1155.hasRole(MINTER_ROLE, ADDRESS["PackHandler"])
  if(!handlerHasMinterRole) {
    throw new Error("PackHandler does not have minter role.")
  } else {
    console.log("Handler has been granted minter role");
  }
}


main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });