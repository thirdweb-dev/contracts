// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

//  ==========  External imports    ==========
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

//  ==========  Internal imports    ==========

import "../interfaces/airdrop/IAirdropERC1155.sol";

//  ==========  Features    ==========
import "../extension/Ownable.sol";
import "../extension/PermissionsEnumerable.sol";

contract AirdropERC1155 is
    Initializable,
    Ownable,
    PermissionsEnumerable,
    ReentrancyGuardUpgradeable,
    MulticallUpgradeable,
    IAirdropERC1155
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("AirdropERC1155");
    uint256 private constant VERSION = 1;

    uint256 public payeeCount;
    uint256 public processedCount;

    uint256[] public indicesOfFailed;

    mapping(uint256 => AirdropContent) private airdropContent;

    CancelledPayments[] public cancelledPaymentIndices;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor() initializer {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(address _defaultAdmin) external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupOwner(_defaultAdmin);
        __ReentrancyGuard_init();
    }

    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /*///////////////////////////////////////////////////////////////
                            Airdrop logic
    //////////////////////////////////////////////////////////////*/

    ///@notice Lets contract-owner set up an airdrop of ERC721 NFTs to a list of addresses.
    function addRecipients(AirdropContent[] calldata _contents) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 len = _contents.length;
        require(len > 0, "No payees provided.");

        uint256 currentCount = payeeCount;
        payeeCount += len;

        for (uint256 i = 0; i < len; ) {
            airdropContent[i + currentCount] = _contents[i];

            unchecked {
                i += 1;
            }
        }

        emit RecipientsAdded(currentCount, currentCount + len);
    }

    ///@notice Lets contract-owner cancel any pending payments.
    function cancelPendingPayments(uint256 numberOfPaymentsToCancel) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 countOfProcessed = processedCount;

        // increase processedCount by the specified count -- all pending payments in between will be treated as cancelled.
        uint256 newProcessedCount = countOfProcessed + numberOfPaymentsToCancel;
        require(newProcessedCount <= payeeCount, "Exceeds total payees.");
        processedCount = newProcessedCount;

        CancelledPayments memory range = CancelledPayments({
            startIndex: countOfProcessed,
            endIndex: newProcessedCount - 1
        });

        cancelledPaymentIndices.push(range);

        emit PaymentsCancelledByAdmin(countOfProcessed, newProcessedCount - 1);
    }

    /// @notice Lets contract-owner send ERC721 NFTs to a list of addresses.
    function processPayments(uint256 paymentsToProcess) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 totalPayees = payeeCount;
        uint256 countOfProcessed = processedCount;

        require(countOfProcessed + paymentsToProcess <= totalPayees, "invalid no. of payments");

        processedCount += paymentsToProcess;

        for (uint256 i = countOfProcessed; i < (countOfProcessed + paymentsToProcess); ) {
            AirdropContent memory content = airdropContent[i];

            bool failed;
            try
                IERC1155(content.tokenAddress).safeTransferFrom{ gas: 80_000 }(
                    content.tokenOwner,
                    content.recipient,
                    content.tokenId,
                    content.amount,
                    ""
                )
            {} catch {
                // revert if failure is due to unapproved tokens
                require(
                    IERC1155(content.tokenAddress).balanceOf(content.tokenOwner, content.tokenId) >= content.amount &&
                        IERC1155(content.tokenAddress).isApprovedForAll(content.tokenOwner, address(this)),
                    "Not balance or approved"
                );

                // record and continue for all other failures, likely originating from recipient accounts
                indicesOfFailed.push(i);
                failed = true;
            }

            emit AirdropPayment(content.recipient, i, failed);

            unchecked {
                i += 1;
            }
        }
    }

    /**
     *  @notice          Lets contract-owner send ERC1155 tokens to a list of addresses.
     *  @dev             The token-owner should approve target tokens to Airdrop contract,
     *                   which acts as operator for the tokens.
     *
     *  @param _contents        List containing recipient, tokenId and amounts to airdrop.
     */
    function airdrop(AirdropContent[] calldata _contents) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 len = _contents.length;

        for (uint256 i = 0; i < len; ) {
            bool failed;
            try
                IERC1155(_contents[i].tokenAddress).safeTransferFrom(
                    _contents[i].tokenOwner,
                    _contents[i].recipient,
                    _contents[i].tokenId,
                    _contents[i].amount,
                    ""
                )
            {} catch {
                // revert if failure is due to unapproved tokens
                require(
                    IERC1155(_contents[i].tokenAddress).balanceOf(_contents[i].tokenOwner, _contents[i].tokenId) >=
                        _contents[i].amount &&
                        IERC1155(_contents[i].tokenAddress).isApprovedForAll(_contents[i].tokenOwner, address(this)),
                    "Not balance or approved"
                );

                failed = true;
            }

            emit StatelessAirdrop(_contents[i].recipient, _contents[i], failed);

            unchecked {
                i += 1;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Airdrop view logic
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns all airdrop payments set up -- pending, processed or failed.
    function getAllAirdropPayments(uint256 startId, uint256 endId)
        external
        view
        returns (AirdropContent[] memory contents)
    {
        require(startId <= endId && endId < payeeCount, "invalid range");

        contents = new AirdropContent[](endId - startId + 1);

        for (uint256 i = startId; i <= endId; i += 1) {
            contents[i - startId] = airdropContent[i];
        }
    }

    /// @notice Returns all pending airdrop payments.
    function getAllAirdropPaymentsPending(uint256 startId, uint256 endId)
        external
        view
        returns (AirdropContent[] memory contents)
    {
        require(startId <= endId && endId < payeeCount, "invalid range");

        uint256 processed = processedCount;
        if (processed == payeeCount) {
            return contents;
        }

        if (startId < processed) {
            startId = processed;
        }
        contents = new AirdropContent[](endId - startId + 1);

        uint256 idx;
        for (uint256 i = startId; i <= endId; i += 1) {
            contents[idx] = airdropContent[i];
            idx += 1;
        }
    }

    /// @notice Returns all pending airdrop failed.
    function getAllAirdropPaymentsFailed() external view returns (AirdropContent[] memory contents) {
        uint256 count = indicesOfFailed.length;
        contents = new AirdropContent[](count);

        for (uint256 i = 0; i < count; i += 1) {
            contents[i] = airdropContent[indicesOfFailed[i]];
        }
    }

    /// @notice Returns all blocks of cancelled payments as an array of index range.
    function getCancelledPaymentIndices() external view returns (CancelledPayments[] memory) {
        return cancelledPaymentIndices;
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
