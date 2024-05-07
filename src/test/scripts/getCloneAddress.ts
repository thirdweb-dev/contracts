const { MerkleTree } = require("@thirdweb-dev/merkletree");

const keccak256 = require("keccak256");
const { ethers } = require("ethers");

const process = require("process");

let implementationAddress = process.argv[2];
let signer = process.argv[3];
let salthash = process.argv[4];

const cloneBytecode = [
  "0x3d602d80600a3d3981f3363d3d373d3d3d363d73",
  implementationAddress.replace(/0x/, "").toLowerCase(),
  "5af43d82803e903d91602b57fd5bf3",
].join("");

const initCodeHash = ethers.utils.solidityKeccak256(["bytes"], [cloneBytecode]);

const create2Address = ethers.utils.getCreate2Address(signer, salthash, initCodeHash);

process.stdout.write(create2Address);
// process.stdout.write(ethers.utils.defaultAbiCoder.encode(["bytes32"], [create2Address]));
