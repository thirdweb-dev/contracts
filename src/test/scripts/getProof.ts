const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const { ethers } = require("ethers");

const process = require("process");

const members = [
  "0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3",
  "0xD0d82c095d184e6E2c8B72689c9171DE59FFd28d",
  "0xFD78F7E2dF2B8c3D5bff0413c96f3237500898B3",
];

let val = process.argv[2];
let price = process.argv[3];
let currency = process.argv[4];

const hashedLeafs = members.map(l =>
  ethers.utils.solidityKeccak256(["address", "uint256", "uint256", "address"], [l, val, price, currency]),
);

const tree = new MerkleTree(hashedLeafs, keccak256, {
  sort: true,
  sortLeaves: true,
  sortPairs: true,
});

const expectedProof = tree.getHexProof(
  ethers.utils.solidityKeccak256(["address", "uint256", "uint256", "address"], [members[0], val, price, currency]),
);

process.stdout.write(ethers.utils.defaultAbiCoder.encode(["bytes32[]"], [expectedProof]));
