const ethers = require("ethers");
const { DefenderRelaySigner, DefenderRelayProvider } = require("defender-relay-client/lib/ethers");

exports.handler = async function (event) {
  // Forwarder details
  const ForwarderAddress = "0xF2c1F9c70e0E09835ABfD89d7D2E0a9358Cc3A91";
  const ForwarderAbi = [
    { inputs: [], stateMutability: "nonpayable", type: "constructor" },
    {
      inputs: [
        {
          components: [
            { internalType: "address", name: "from", type: "address" },
            { internalType: "address", name: "to", type: "address" },
            { internalType: "uint256", name: "value", type: "uint256" },
            { internalType: "uint256", name: "gas", type: "uint256" },
            { internalType: "uint256", name: "nonce", type: "uint256" },
            { internalType: "bytes", name: "data", type: "bytes" },
          ],
          internalType: "struct MinimalForwarder.ForwardRequest",
          name: "req",
          type: "tuple",
        },
        { internalType: "bytes", name: "signature", type: "bytes" },
      ],
      name: "execute",
      outputs: [
        { internalType: "bool", name: "", type: "bool" },
        { internalType: "bytes", name: "", type: "bytes" },
      ],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [{ internalType: "address", name: "from", type: "address" }],
      name: "getNonce",
      outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        {
          components: [
            { internalType: "address", name: "from", type: "address" },
            { internalType: "address", name: "to", type: "address" },
            { internalType: "uint256", name: "value", type: "uint256" },
            { internalType: "uint256", name: "gas", type: "uint256" },
            { internalType: "uint256", name: "nonce", type: "uint256" },
            { internalType: "bytes", name: "data", type: "bytes" },
          ],
          internalType: "struct MinimalForwarder.ForwardRequest",
          name: "req",
          type: "tuple",
        },
        { internalType: "bytes", name: "signature", type: "bytes" },
      ],
      name: "verify",
      outputs: [{ internalType: "bool", name: "", type: "bool" }],
      stateMutability: "view",
      type: "function",
    },
  ];

  // Parse webhook payload
  if (!event.request || !event.request.body) throw new Error(`Missing payload`);
  const { request, signature } = event.request.body;
  console.log(`Relaying`, request);

  // Initialize Relayer provider and signer, and forwarder contract
  const credentials = { ...event };
  const provider = new DefenderRelayProvider(credentials);
  const signer = new DefenderRelaySigner(credentials, provider, { speed: "fast" });
  const forwarder = new ethers.Contract(ForwarderAddress, ForwarderAbi, signer);

  //  ===== Relay transaction!  =====

  // Validate request on the forwarder contract
  const valid = await forwarder.verify(request, signature);
  if (!valid) throw new Error(`Invalid request`);

  // Send meta-tx through relayer to the forwarder contract
  const gasLimit = (parseInt(request.gas) + 50000).toString();
  const tx = await forwarder.execute(request, signature, { gasLimit });

  console.log(`Sent meta-tx: ${tx.hash}`);
  return { txHash: tx.hash, receipt: tx };
};
