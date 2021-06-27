require('dotenv').config()
const { ethers } = require('ethers');

const packControlABI = require('../abi/PackControl.json');
const packERC1155ABI = require('../abi/PackERC1155.json');
const packHandlerABI = require('../abi/PackHandler.json');
const packMarketABI = require('../abi/PackMarket.json');
const rngABI = require('../abi/DexRNG.json');

const packControlAddress = "0x481A7Fe771F671fE8a1A4ff4362D28Fd72c042B7";
const packERC1155Address = "0xe280e8BcCF8dD8070B079b6b62d6d4ea3CD992A7";
const rngAddress = "0x1F648fFdDC74b9f1c273B92F2d0D9F8a3F1c844E";
const packHandlerAddress = "0xF0FC15174DB513CE2AbD3F949Cd5F6621D094082";
const packMarketAddress = "0x99C91C3E968367610a1Afe0DeA58048094031f92";

const ABI = {
  "PackControl": packControlABI,
  "PackERC1155": packERC1155ABI,
  "PackHandler": packHandlerABI,
  "PackMarket": packMarketABI,
  "DexRNG": rngABI
}

const ADDRESS = {
  "PackControl": packControlAddress,
  "PackERC1155": packERC1155Address,
  "PackHandler": packHandlerAddress,
  "PackMarket": packMarketAddress,
  "DexRNG": rngAddress
}

const ALCHEMY_KEY = process.env.ALCHEMY_KEY;
const TEST_PRIVATE_KEY = process.env.TEST_PRIVATE_KEY;

function getProvider(network) {
  return new ethers.providers.JsonRpcProvider(`https://eth-${network}.alchemyapi.io/v2/${ALCHEMY_KEY}`)
}

function getWallet(network) {
  const provider = getProvider(network);
  return new ethers.Wallet(TEST_PRIVATE_KEY, provider);
}

function getContract(contractName, network) {
  const wallet = getWallet(network);
  return new ethers.Contract(ADDRESS[contractName], ABI[contractName], wallet);
}

module.exports = {
  ABI,
  ADDRESS,
  getProvider,
  getWallet,
  getContract
}