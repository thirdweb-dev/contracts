// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

//  ==========  Internal imports    ==========

import { IReward } from "./IReward.sol";
import { GameLibrary } from "../core/LibGame.sol";
import { RewardStorage } from "./RewardStorage.sol";

contract Reward is IReward, GameLibrary {
    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Register a reward.
    function registerReward(string calldata identifier, RewardInfo calldata rewardInfo) external onlyManager {
        _registerReward(identifier, rewardInfo);
    }

    /// @dev Update a reward.
    function updateReward(string calldata identifier, RewardInfo calldata rewardInfo) external onlyManager {
        _updateReward(identifier, rewardInfo);
    }

    /// @dev Unregister a reward.
    function unregisterReward(string calldata identifier) external onlyManager {
        _unregisterReward(identifier);
    }

    /// @dev Claim a reward.
    function claimReward(address receiver, string calldata identifier) external onlyManager {
        _claimReward(receiver, identifier);
    }

    /*///////////////////////////////////////////////////////////////
                        Signature-based external functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Register a reward with signature.
    function registerRewardWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        (string memory identifier, RewardInfo memory rewardInfo) = abi.decode(req.data, (string, RewardInfo));
        _registerReward(identifier, rewardInfo);
    }

    /// @dev Update a reward with signature.
    function updateRewardWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        (string memory identifier, RewardInfo memory rewardInfo) = abi.decode(req.data, (string, RewardInfo));
        _updateReward(identifier, rewardInfo);
    }

    /// @dev Unregister a reward with signature.
    function unregisterRewardWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        string memory identifier = abi.decode(req.data, (string));
        _unregisterReward(identifier);
    }

    /// @dev Claim a reward with signature.
    function claimRewardWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        (address receiver, string memory identifier) = abi.decode(req.data, (address, string));
        _claimReward(receiver, identifier);
    }

    /*///////////////////////////////////////////////////////////////
                        View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Get reward information by identifier.
    function getRewardInfo(string calldata identifier) public view returns (RewardInfo memory rewardInfo) {
        bytes32 rewardId = _toBytes32(identifier);
        rewardInfo = RewardStorage.rewardStorage().rewardInfo[rewardId];
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Register a reward.
    function _registerReward(string memory identifier, RewardInfo memory rewardInfo) internal {
        bytes32 rewardId = _toBytes32(identifier);
        RewardStorage.Data storage rs = RewardStorage.rewardStorage();
        if (rewardInfo.rewardAddress == address(0)) revert("Reward: Reward address cannot be zero address");
        if (rs.rewardInfo[rewardId].rewardAddress != address(0)) revert("Reward: Reward already registered");
        rs.rewardInfo[rewardId] = rewardInfo;
        emit RegisterReward(rewardId, rewardInfo);
    }

    /// @dev Update a reward.
    function _updateReward(string memory identifier, RewardInfo memory rewardInfo) internal {
        bytes32 rewardId = _toBytes32(identifier);
        RewardStorage.Data storage rs = RewardStorage.rewardStorage();
        if (rs.rewardInfo[rewardId].rewardAddress == address(0)) revert("Reward: Reward not registered");
        rs.rewardInfo[rewardId] = rewardInfo;
        emit UpdateReward(rewardId, rewardInfo);
    }

    /// @dev Unregister a reward.
    function _unregisterReward(string memory identifier) internal {
        bytes32 rewardId = _toBytes32(identifier);
        RewardStorage.Data storage rs = RewardStorage.rewardStorage();
        if (rs.rewardInfo[rewardId].rewardAddress == address(0)) revert("Reward: Reward not registered");
        delete rs.rewardInfo[rewardId];
        emit UnregisterReward(rewardId);
    }

    /// @dev Claim a reward.
    function _claimReward(address receiver, string memory identifier) internal {
        bytes32 rewardId = _toBytes32(identifier);
        IReward.RewardInfo memory rewardInfo = RewardStorage.rewardStorage().rewardInfo[rewardId];
        if (rewardInfo.rewardAddress == address(0)) revert("Reward: Reward not registered");
        if (receiver == address(0)) revert("Reward: Receiver cannot be zero address");
        if (rewardInfo.rewardType == RewardType.ERC20) {
            _transferERC20(receiver, rewardInfo.rewardAddress, rewardInfo.rewardAmount);
        } else if (rewardInfo.rewardType == RewardType.ERC721) {
            _transferERC721(receiver, rewardInfo.rewardAddress, rewardInfo.rewardTokenId);
        } else if (rewardInfo.rewardType == RewardType.ERC1155) {
            _transferERC1155(receiver, rewardInfo.rewardAddress, rewardInfo.rewardTokenId, rewardInfo.rewardAmount);
        } else {
            revert("Reward: Invalid reward type");
        }
        emit ClaimReward(receiver, rewardId, rewardInfo);
    }

    /*///////////////////////////////////////////////////////////////
                        Private functions
    //////////////////////////////////////////////////////////////*/

    function _toBytes32(string memory identifier) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(identifier));
    }

    function _transferERC20(
        address receiver,
        address rewardAddress,
        uint256 rewardAmount
    ) private {
        (bool success, bytes memory data) = rewardAddress.call(
            abi.encodeWithSelector(0xa9059cbb, receiver, rewardAmount)
        );
        if (!success) {
            if (data.length > 0) {
                assembly {
                    revert(add(data, 32), mload(data))
                }
            } else {
                revert("Reward: Transfer ERC20 failed");
            }
        }
    }

    function _transferERC721(
        address receiver,
        address rewardAddress,
        uint256 rewardTokenId
    ) private {
        (bool success, bytes memory data) = rewardAddress.call(
            abi.encodeWithSelector(0x40c10f19, receiver, rewardTokenId)
        );
        if (!success) {
            if (data.length > 0) {
                assembly {
                    revert(add(data, 32), mload(data))
                }
            } else {
                revert("Reward: Transfer ERC721 failed");
            }
        }
    }

    function _transferERC1155(
        address receiver,
        address rewardAddress,
        uint256 rewardTokenId,
        uint256 rewardAmount
    ) private {
        (bool success, bytes memory data) = rewardAddress.call(
            abi.encodeWithSelector(0xa22cb465, receiver, rewardTokenId, rewardAmount, "")
        );
        if (!success) {
            if (data.length > 0) {
                assembly {
                    revert(add(data, 32), mload(data))
                }
            } else {
                revert("Reward: Transfer ERC1155 failed");
            }
        }
    }
}
