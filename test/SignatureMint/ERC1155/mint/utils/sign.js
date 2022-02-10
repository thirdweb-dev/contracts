const ethSigUtil = require("eth-sig-util");

const EIP712Domain = [
  { name: "name", type: "string" },
  { name: "version", type: "string" },
  { name: "chainId", type: "uint256" },
  { name: "verifyingContract", type: "address" },
];

const MintRequest = [
  { name: "to", type: "address" },
  { name: "royaltyRecipient", type: "address" },
  { name: "primarySaleRecipient", type: "address" },
  { name: "tokenId", type: "uint256" },
  { name: "uri", type: "string" },
  { name: "quantity", type: "uint256" },
  { name: "pricePerToken", type: "uint256" },
  { name: "currency", type: "address" },
  { name: "validityStartTimestamp", type: "uint128" },
  { name: "validityEndTimestamp", type: "uint128" },
  { name: "uid", type: "bytes32" },
];

function getMetaTxTypeData(chainId, verifyingContract) {
  return {
    types: {
      EIP712Domain,
      MintRequest,
    },
    domain: {
      name: "SignatureMint1155", // Hardcoded in the contract constructor
      version: "1", // Hardcoded in the contract constructor
      chainId,
      verifyingContract,
    },
    primaryType: "MintRequest",
  };
}

async function signTypedData(signerProvider, from, data) {
  // If signer is a private key, use it to sign
  if (typeof signerProvider === "string") {
    const privateKey = Buffer.from(signerProvider.replace(/^0x/, ""), "hex");
    return ethSigUtil.signTypedMessage(privateKey, { data });
  }

  const [method, argData] = ["eth_signTypedData_v4", JSON.stringify(data)];
  return await signerProvider.send(method, [from, argData]);
}

async function buildTypedData(sigMint721, request) {
  const chainId = await sigMint721.provider.getNetwork().then(n => n.chainId);
  const typeData = getMetaTxTypeData(chainId, sigMint721.address);
  return { ...typeData, message: request };
}

async function signMintRequest(signerProvider, signer, sigMint721, request) {
  const toSign = await buildTypedData(sigMint721, request);
  const signature = await signTypedData(signerProvider, signer.address, toSign);
  return { signature, request };
}

module.exports = {
  signMintRequest,
};
