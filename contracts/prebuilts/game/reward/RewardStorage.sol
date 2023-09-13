// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IReward } from "./IReward.sol";

library RewardStorage {
    bytes32 public constant REWARD_STORAGE_POSITION = keccak256("reward.storage");

    struct Data {
        mapping(bytes32 => IReward.RewardInfo) rewardInfo;
    }

    function rewardStorage() internal pure returns (Data storage rewardData) {
        bytes32 position = REWARD_STORAGE_POSITION;
        assembly {
            rewardData.slot := position
        }
    }
}
