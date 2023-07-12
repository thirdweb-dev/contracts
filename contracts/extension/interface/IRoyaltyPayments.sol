// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Read royalty info for a token.
 *      Supports RoyaltyEngineV1 and RoyaltyRegistry by manifold.xyz.
 */
interface IRoyaltyPayments is IERC165 {
    /// @dev Emitted when the address of RoyaltyEngine is set or updated.
    event RoyaltyEngineUpdated(address indexed previousAddress, address indexed newAddress);

    /**
     * Get the royalty for a given token (address, id) and value amount.
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    ) external returns (address payable[] memory recipients, uint256[] memory amounts);

    /**
     * Set or override RoyaltyEngine address
     *
     * @param _royaltyEngineAddress - RoyaltyEngineV1 address
     */
    function setRoyaltyEngine(address _royaltyEngineAddress) external;
}
