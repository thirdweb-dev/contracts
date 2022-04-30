// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IThirdwebPlatformFee.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

abstract contract PlatformFee is IThirdwebPlatformFee, AccessControlEnumerableUpgradeable {

    /// @dev The address that receives all platform fees from all sales.
    address private platformFeeRecipient;

    /// @dev The % of primary sales collected as platform fees.
    uint16 private platformFeeBps;
    
    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo() public view returns (address, uint16) {
        return (platformFeeRecipient, uint16(platformFeeBps));
    }

    /// @dev Lets a contract admin update the platform fee recipient and bps
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_platformFeeBps <= 10_000, "exceeds max bps.");

        platformFeeBps = uint16(_platformFeeBps);
        platformFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
    }
}