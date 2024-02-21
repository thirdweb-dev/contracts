// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../interface/IRoyaltyPayments.sol";
import "../interface/IRoyaltyEngineV1.sol";
import { IERC2981 } from "../../eip/interface/IERC2981.sol";

library RoyaltyPaymentsStorage {
    /// @custom:storage-location erc7201:royalty.payments.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("royalty.payments.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant ROYALTY_PAYMENTS_STORAGE_POSITION =
        0xc802b338f3fb784853cf3c808df5ff08335200e394ea2c687d12571a91045000;

    struct Data {
        /// @dev The address of RoyaltyEngineV1, replacing the one set during construction.
        address royaltyEngineAddressOverride;
    }

    function royaltyPaymentsStorage() internal pure returns (Data storage royaltyPaymentsData) {
        bytes32 position = ROYALTY_PAYMENTS_STORAGE_POSITION;
        assembly {
            royaltyPaymentsData.slot := position
        }
    }
}

/**
 *  @author  thirdweb.com
 *
 *  @title   Royalty Payments
 *  @notice  Thirdweb's `RoyaltyPayments` is a contract extension to be used with a marketplace contract.
 *           It exposes functions for fetching royalty settings for a token.
 *           It Supports RoyaltyEngineV1 and RoyaltyRegistry by manifold.xyz.
 */

abstract contract RoyaltyPaymentsLogic is IRoyaltyPayments {
    // solhint-disable-next-line var-name-mixedcase
    address immutable ROYALTY_ENGINE_ADDRESS;

    constructor(address _royaltyEngineAddress) {
        // allow address(0) in case RoyaltyEngineV1 not present on a network
        require(
            _royaltyEngineAddress == address(0) ||
                IERC165(_royaltyEngineAddress).supportsInterface(type(IRoyaltyEngineV1).interfaceId),
            "Doesn't support IRoyaltyEngineV1 interface"
        );

        ROYALTY_ENGINE_ADDRESS = _royaltyEngineAddress;
    }

    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
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
    ) external returns (address payable[] memory recipients, uint256[] memory amounts) {
        address royaltyEngineAddress = getRoyaltyEngineAddress();

        if (royaltyEngineAddress == address(0)) {
            try IERC2981(tokenAddress).royaltyInfo(tokenId, value) returns (address recipient, uint256 amount) {
                require(amount <= value, "Invalid royalty amount");

                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = payable(recipient);
                amounts[0] = amount;
            } catch {}
        } else {
            (recipients, amounts) = IRoyaltyEngineV1(royaltyEngineAddress).getRoyalty(tokenAddress, tokenId, value);
        }
    }

    /**
     * Set or override RoyaltyEngine address
     *
     * @param _royaltyEngineAddress - RoyaltyEngineV1 address
     */
    function setRoyaltyEngine(address _royaltyEngineAddress) external {
        if (!_canSetRoyaltyEngine()) {
            revert("Not authorized");
        }

        require(
            _royaltyEngineAddress != address(0) &&
                IERC165(_royaltyEngineAddress).supportsInterface(type(IRoyaltyEngineV1).interfaceId),
            "Doesn't support IRoyaltyEngineV1 interface"
        );

        _setupRoyaltyEngine(_royaltyEngineAddress);
    }

    /// @dev Returns original or overridden address for RoyaltyEngineV1
    function getRoyaltyEngineAddress() public view returns (address royaltyEngineAddress) {
        RoyaltyPaymentsStorage.Data storage data = RoyaltyPaymentsStorage.royaltyPaymentsStorage();
        address royaltyEngineOverride = data.royaltyEngineAddressOverride;
        royaltyEngineAddress = royaltyEngineOverride != address(0) ? royaltyEngineOverride : ROYALTY_ENGINE_ADDRESS;
    }

    /// @dev Lets a contract admin update the royalty engine address
    function _setupRoyaltyEngine(address _royaltyEngineAddress) internal {
        RoyaltyPaymentsStorage.Data storage data = RoyaltyPaymentsStorage.royaltyPaymentsStorage();
        address currentAddress = data.royaltyEngineAddressOverride;

        data.royaltyEngineAddressOverride = _royaltyEngineAddress;

        emit RoyaltyEngineUpdated(currentAddress, _royaltyEngineAddress);
    }

    /// @dev Returns whether royalty engine address can be set in the given execution context.
    function _canSetRoyaltyEngine() internal view virtual returns (bool);
}
