import { ethers } from "ethers";

/**
     function encryptDecrypt(bytes memory data, bytes memory key) public pure returns (bytes memory result) {
        // Store data length on stack for later use
        uint256 length = data.length;

        assembly {
            // Set result to free memory pointer
            result := mload(0x40)
            // Increase free memory pointer by lenght + 32
            mstore(0x40, add(add(result, length), 32))
            // Set result length
            mstore(result, length)
        }

        // Iterate over the data stepping by 32 bytes
        for (uint256 i = 0; i < length; i += 32) {
            // Generate hash of the key and offset
            bytes32 hash = keccak256(abi.encodePacked(key, i));

            bytes32 chunk;
            assembly {
                // Read 32-bytes data chunk
                chunk := mload(add(data, add(i, 32)))
            }
            // XOR the chunk with hash
            chunk ^= hash;
            assembly {
                // Write 32-byte encrypted chunk
                mstore(add(result, add(i, 32)), chunk)
            }
        }
    }
*/

function xor(data: Uint8Array, key: Uint8Array) {
  const len = data.length;
  const result = [];
  for (let i = 0; i < len; i += 32) {
    const hash = ethers.utils.solidityKeccak256(["bytes", "uint256"], [key, i]);
    const slice = data.slice(i, i + 32);
    const hashsliced = ethers.utils.arrayify(hash).slice(0, slice.length); // weird that we need to slice the hash
    const chunk = ethers.BigNumber.from(slice).xor(hashsliced);
    result.push(chunk);
  }
  return `0x${result.map(chunk => chunk.toHexString().substring(2)).join("")}`;
}

async function run() {
  //console.log(ethers.utils.id("hello"));
  const text = "ipfs://secret_this_is_a_super_long_ipfs_url_maybe_you_will_find_it_useful/";
  //const expected =
  //"0xe23d08b128c4405cfd8e350d383a52b3ad42cb244328b3bdfbc58aee4d7221cbab5bc7321dd0006044e5e7392dc8807dc5d2bd231d251067fc445467064ee964f41e4d35a062574422b8";
  //const x = xor(ethers.utils.toUtf8Bytes(text), ethers.utils.toUtf8Bytes("secret"));
}

run();
