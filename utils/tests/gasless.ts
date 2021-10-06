// Types
import { BytesLike } from "@ethersproject/bytes";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Forwarder } from "../../typechain/Forwarder";

// Signature
const { signMetaTxRequest } = require("../meta-tx/signer");

type Payload = {
  from: string;
  to: string;
  data: BytesLike;
};

export async function sendGaslessTx(
  signer: SignerWithAddress,
  forwarder: Forwarder,
  relayer: SignerWithAddress,
  payload: Payload,
) {
  // Get params
  const { from, to, data } = payload;

  // Sign tx request
  const { request, signature } = await signMetaTxRequest(signer.provider, forwarder, { from, to, data });

  // Call forwarder with signed tx request
  await forwarder.connect(relayer).execute(request, signature);
}
