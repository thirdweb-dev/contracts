const { getContract } = require('../contractUtils');

async function main() {

  // Get contract
  const packHandler = getContract("PackHandler", "rinkeby");
  const packERC1155 = getContract("PackERC1155", "rinkeby");

  // Get parameters
  const numOfPacks = 50;
  const rewardsPerPack = 3;

  const packURIs = []
  const rewardURIs = []
  const rewardMaxSupplies = []

  for(let i = 0; i < numOfPacks; i++) {
    packURIs.push(`This is a dummy pack no. ${i}`)

    if(i < rewardsPerPack) {
      rewardURIs.push(`This is a dummy reward no. ${i}`)
      rewardMaxSupplies.push(10 + Math.floor(Math.random() * 100));
    }
  }

  console.log("Num of packs: ", packURIs.length, "Num of rewards: ", rewardURIs.length);

  for(let packURI of packURIs) {
    try {
      const packId = parseInt((await packERC1155.currentTokenId()).toString());
      console.log("Creating pack with ID: ", packId);

      const createTx = await packHandler.createPack(packURI, rewardURIs, rewardMaxSupplies, {
        gasLimit: 1000000
      });
      console.log("Creating pack: ", createTx.hash);
      await createTx.wait();
      console.log("SUCCESS\n")
    } catch(err) {
      console.error(err);
    }
  }

  console.log("All packs created successfully");
}

main()
  .then(() => process.exit(0))
  .catch(err => {
    console.log(err)
    process.exit(1);
  })