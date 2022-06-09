import hre, { ethers } from "hardhat";
import { TWRegistry } from "typechain";

//  ====================================

// REPLACE according to desired date range.
const startBlock: number = 14853262;
const endBlock: number = 14933262;

async function main() {

    const chainId: number = hre.network.config.chainId as number;
    console.log(`\nGetting the number of pre-built contracts deployed:\nChain: ${chainId}\nStart block: ${startBlock}  End block: ${endBlock}`)
    
    const twRegistry: TWRegistry = await ethers.getContractAt("TWRegistry", "0x7c487845f98938Bb955B1D5AD069d9a30e4131fd");

    const filter = twRegistry.filters.Added();
    const events = await twRegistry.queryFilter(filter, startBlock, endBlock);

    console.log(events.length);
}

main()
  .then(() => process.exit(0))
  .catch(e => {
    console.error(e);
    process.exit(1);
  });