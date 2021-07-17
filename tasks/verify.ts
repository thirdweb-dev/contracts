import hre from 'hardhat'

async function verify() {
  await hre.run("verify:verify", {
    address: "0x5ECC47810De05F49728Abe629f59FF020D4b5d92",
    constructorArguments: [
      "0xb08E08f4B0A88eaFc1446e703390Ad49dB7507e8",
      "$PACK Protocol",
    ],
  });
}

verify()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err)
    process.exit(1)
  })
