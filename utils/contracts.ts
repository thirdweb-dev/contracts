import * as dotenv from "dotenv";
import { chainIds } from "./chainIds";
import addresses from "./address.json";

dotenv.config();

export async function getContractAddress(name: "protocolControl" | "pack" | "market" | "rewards", chainId: number) {
  for (let network of Object.keys(chainIds)) {
    if (chainIds[network as keyof typeof chainIds] == chainId) {
      return addresses[network as keyof typeof addresses][name];
    }
  }
}
