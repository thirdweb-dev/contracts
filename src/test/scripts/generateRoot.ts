const { MerkleTree } = require("@thirdweb-dev/merkletree");

const keccak256 = require("keccak256");
const { ethers } = require("ethers");

const process = require("process");

const members = [
  "0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3",
  "0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd",
  "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
];

let val = process.argv[2];
let price = process.argv[3];
let currency = process.argv[4];

const hashedLeafs = members.map(l =>
  ethers.utils.solidityKeccak256(
    ["address", "uint256", "uint256", "address"],
    [l, val, price, currency],
  ),
);

const tree = new MerkleTree(hashedLeafs, keccak256, {
  sort: true,
  sortLeaves: true,
  sortPairs: true,
});

process.stdout.write(ethers.utils.defaultAbiCoder.encode(["bytes32"], [tree.getHexRoot()]));
