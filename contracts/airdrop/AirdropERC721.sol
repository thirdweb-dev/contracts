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
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

import "lib/sstore2/contracts/SSTORE2.sol";

//  ==========  Internal imports    ==========

import "../interfaces/airdrop/IAirdropERC721.sol";

//  ==========  Features    ==========
import "../extension/Ownable.sol";
import "../extension/PermissionsEnumerable.sol";
import "../extension/BatchAirdropContent.sol";

contract AirdropERC721 is
    Initializable,
    Ownable,
    PermissionsEnumerable,
    BatchAirdropContent,
    ReentrancyGuardUpgradeable,
    MulticallUpgradeable,
    IAirdropERC721
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("AirdropERC721");
    uint256 private constant VERSION = 1;

    uint256 private constant CONTENT_COUNT_FOR_POINTER = 100;

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
    function addRecipients(
        address tokenOwner,
        address tokenAddress,
        AirdropContent[] calldata _contents
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 len = _contents.length;
        require(len > 0, "No payees provided.");

        uint256 currentCount = payeeCount;
        payeeCount += len;

        AirdropContent storage batch = _saveAirdropBatch(tokenOwner, tokenAddress, currentCount + len);

        uint256 size = len > CONTENT_COUNT_FOR_POINTER ? CONTENT_COUNT_FOR_POINTER : len;
        AirdropContent[] memory tempContent = new AirdropContent[](size);

        uint256 tempContentIndex = 0;
        for (uint256 i = 0; i < len; ) {
            // airdropContent[i + currentCount] = _contents[i];
            tempContent[tempContentIndex++] = _contents[i];

            if (tempContentIndex == CONTENT_COUNT_FOR_POINTER - 1) {
                address pointer = SSTORE2.write(abi.encode(tempContent));
                batch.pointers.push(pointer);

                uint256 size = (len - i - 1) > CONTENT_COUNT_FOR_POINTER ? CONTENT_COUNT_FOR_POINTER : (len - i - 1);
                tempContent = new AirdropContent[](size);
                tempContentIndex = 0;
                continue;
            }

            unchecked {
                i += 1;
            }
        }

        if (tempContent.length > 0) {
            address pointer = SSTORE2.write(abi.encode(tempContent));
            batch.pointers.push(pointer);
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

        (uint256 _startBatchId, uint256 _endBatchId) = _getBatchesToProcess(
            countOfProcessed,
            countOfProcessed + paymentsToProcess
        );

        processedCount += paymentsToProcess;

        uint256 remainingPayments = paymentsToProcess;
        for (uint256 i = _startBatchId; i <= _endBatchId; i++) {
            AirdropBatch memory batch = _getBatch(i);
            uint256 _paymentCount = countOfProcessed + remainingPayments < batch.batchEndIndex
                ? countOfProcessed + paymentsToProcess
                : batch.batchEndIndex;

            uint256 _totalPointers = batch.pointers.length;
            uint256 _pointerIdToProcess = batch.pointerIdToProcess;

            while (_pointerIdToProcess < _totalPointers) {
                bytes memory pointerData = SSTORE2.read(batch.pointers[_pointerIdToProcess]);
                AirdropContent[] memory content = abi.decode(pointerData, (AirdropContent[]));

                for (uint256 j = 0; j < content.length && remainingPayments > 0; ) {
                    remainingPayments--;
                    bool failed;
                    try
                        IERC721(batch.tokenAddress).safeTransferFrom{ gas: 80_000 }(
                            batch.tokenOwner,
                            content.recipient,
                            content.tokenId
                        )
                    {} catch {
                        // revert if failure is due to unapproved tokens
                        require(
                            (IERC721(batch.tokenAddress).ownerOf(content.tokenId) == batch.tokenOwner &&
                                address(this) == IERC721(batch.tokenAddress).getApproved(content.tokenId)) ||
                                IERC721(batch.tokenAddress).isApprovedForAll(batch.tokenOwner, address(this)),
                            "Not owner or approved"
                        );

                        // record all other failures, likely originating from recipient accounts
                        indicesOfFailed.push(j);
                        failed = true;
                    }

                    emit AirdropPayment(content.recipient, j, failed);

                    unchecked {
                        j += 1;
                    }
                }
            }
        }
    }

    /**
     *  @notice          Lets contract-owner send ERC721 tokens to a list of addresses.
     *  @dev             The token-owner should approve target tokens to Airdrop contract,
     *                   which acts as operator for the tokens.
     *
     *  @param _contents        List containing recipient, tokenId to airdrop.
     */
    function airdrop(
        address tokenOwner,
        address tokenAddress,
        AirdropContent[] calldata _contents
    ) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 len = _contents.length;

        for (uint256 i = 0; i < len; ) {
            bool failed;
            try
                IERC721(tokenAddress).safeTransferFrom(tokenOwner, _contents[i].recipient, _contents[i].tokenId)
            {} catch {
                // revert if failure is due to unapproved tokens
                require(
                    (IERC721(tokenAddress).ownerOf(_contents[i].tokenId) == tokenOwner &&
                        address(this) == IERC721(tokenAddress).getApproved(_contents[i].tokenId)) ||
                        IERC721(tokenAddress).isApprovedForAll(tokenOwner, address(this)),
                    "Not owner or approved"
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

        uint256 index;
        for (uint256 i = startId; i <= endId; i += 1) {
            contents[index++] = airdropContent[i];
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
