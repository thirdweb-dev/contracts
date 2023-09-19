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

import { GameLibrary } from "../core/LibGame.sol";
import { IReward } from "../reward/IReward.sol";
import { IAchievement } from "./IAchievement.sol";
import { AchievementStorage } from "./AchievementStorage.sol";

contract Achievement is IAchievement, GameLibrary {
    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Create a new achievement.
    function createAchievement(string calldata identifier, AchievementInfo calldata achievementInfo)
        external
        onlyManager
    {
        _createAchievement(identifier, achievementInfo);
    }

    /// @dev Update an existing achievement.
    function updateAchievement(string calldata identifier, AchievementInfo calldata achievementInfo)
        external
        onlyManager
    {
        _updateAchievement(identifier, achievementInfo);
    }

    /// @dev Delete an achievement.
    function deleteAchievement(string calldata identifier) external onlyManager {
        _deleteAchievement(identifier);
    }

    /// @dev Claim an achievement and associated reward.
    function claimAchievement(address receiver, string calldata identifier) external onlyManager {
        _claimAchievement(receiver, identifier);
    }

    /*///////////////////////////////////////////////////////////////
                        Signature-based external functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Create a new achievement with a signature.
    function createAchievementWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        (string memory identifier, AchievementInfo memory achievementInfo) = abi.decode(
            req.data,
            (string, AchievementInfo)
        );
        _createAchievement(identifier, achievementInfo);
    }

    /// @dev Update an existing achievement with a signature.
    function updateAchievementWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        (string memory identifier, AchievementInfo memory achievementInfo) = abi.decode(
            req.data,
            (string, AchievementInfo)
        );
        _updateAchievement(identifier, achievementInfo);
    }

    /// @dev Delete an achievement with a signature.
    function deleteAchievementWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        string memory identifier = abi.decode(req.data, (string));
        _deleteAchievement(identifier);
    }

    /// @dev Claim an achievement with a signature.
    function claimAchievementWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        (address receiver, string memory identifier) = abi.decode(req.data, (address, string));
        _claimAchievement(receiver, identifier);
    }

    /*///////////////////////////////////////////////////////////////
                        View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Get achievement information by identifier.
    function getAchievementInfo(string calldata identifier)
        public
        view
        returns (AchievementInfo memory achievementInfo)
    {
        bytes32 achievementId = _toBytes32(identifier);
        achievementInfo = AchievementStorage.achievementStorage().achievementInfo[achievementId];
    }

    /// @dev Get the claim count for a specific player and achievement.
    function getAchievementClaimCount(address player, string calldata identifier) public view returns (uint256 count) {
        bytes32 achievementId = _toBytes32(identifier);
        count = AchievementStorage.achievementStorage().claimCount[player][achievementId];
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Create a new achievement.
    function _createAchievement(string memory identifier, AchievementInfo memory achievementInfo) internal {
        bytes32 achievementId = _toBytes32(identifier);
        AchievementStorage.Data storage data = AchievementStorage.achievementStorage();
        if (data.achievementInfo[achievementId].isActive) revert("Achievement: Already created");
        data.achievementInfo[achievementId] = achievementInfo;
        emit CreateAchievement(achievementId, achievementInfo);
    }

    /// @dev Update an existing achievement.
    function _updateAchievement(string memory identifier, AchievementInfo memory achievementInfo) internal {
        bytes32 achievementId = _toBytes32(identifier);
        AchievementStorage.Data storage data = AchievementStorage.achievementStorage();
        data.achievementInfo[achievementId] = achievementInfo;
        emit UpdateAchievement(achievementId, achievementInfo);
    }

    /// @dev Delete an achievement.
    function _deleteAchievement(string memory identifier) internal {
        bytes32 achievementId = _toBytes32(identifier);
        AchievementStorage.Data storage data = AchievementStorage.achievementStorage();
        if (!data.achievementInfo[achievementId].isActive) revert("Achievement: Already deleted");
        delete data.achievementInfo[achievementId];
        emit DeleteAchievement(achievementId);
    }

    /// @dev Claim an achievement and associated reward.
    function _claimAchievement(address receiver, string memory identifier) internal {
        bytes32 achievementId = _toBytes32(identifier);
        AchievementStorage.Data storage data = AchievementStorage.achievementStorage();
        if (!data.achievementInfo[achievementId].isActive) revert("Achievement: Inactive");
        if (data.achievementInfo[achievementId].canOnlyClaimOnce && data.claimCount[receiver][achievementId] != 0)
            revert("Achievement: Already claimed");
        ++data.claimCount[receiver][achievementId];
        bytes32 rewardId = _toBytes32(data.achievementInfo[achievementId].rewardId);
        if (rewardId != bytes32(0)) {
            IReward(address(this)).claimReward(receiver, data.achievementInfo[achievementId].rewardId);
        }
        emit ClaimAchievement(receiver, achievementId, data.achievementInfo[achievementId]);
    }

    /*///////////////////////////////////////////////////////////////
                        Private functions
    //////////////////////////////////////////////////////////////*/

    function _toBytes32(string memory identifier) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(identifier));
    }
}
