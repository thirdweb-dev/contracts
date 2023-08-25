// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IGameSignature {
    struct GameRequest {
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
        bytes32 uid;
        bytes data;
    }

    event RequestExecuted(address indexed user, address indexed signer, GameRequest _req);
}
