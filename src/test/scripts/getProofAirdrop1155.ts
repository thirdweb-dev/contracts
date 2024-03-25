const { MerkleTree } = require("@thirdweb-dev/merkletree");

const keccak256 = require("keccak256");
const { ethers } = require("ethers");

const process = require("process");

const members = [
  "0x9999999999999999999999999999999999999999",
  "0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd",
  "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
];

let tokenId = process.argv[2];
let quantity = process.argv[3];

const hashedLeafs = members.map(l =>
  ethers.utils.solidityKeccak256(["address", "uint256", "uint256"], [l, tokenId, quantity]),
);

const tree = new MerkleTree(hashedLeafs, keccak256, {
  sort: true,
  sortLeaves: true,
  sortPairs: true,
});

const expectedProof = tree.getHexProof(
  ethers.utils.solidityKeccak256(["address", "uint256", "uint256"], [members[1], tokenId, quantity]),
);

process.stdout.write(ethers.utils.defaultAbiCoder.encode(["bytes32[]"], [expectedProof]));
