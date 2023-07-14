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

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

//  ==========  Internal imports    ==========

import "../interfaces/airdrop/IAirdropERC20.sol";
import {CurrencyTransferLib} from "../lib/CurrencyTransferLib.sol";
import "../eip/interface/IERC20.sol";

//  ==========  Features    ==========
import "../extension/Ownable.sol";
import "../extension/PermissionsEnumerable.sol";

contract AirdropERC20 is
    Initializable,
    Ownable,
    PermissionsEnumerable,
    ReentrancyGuardUpgradeable,
    MulticallUpgradeable,
    IAirdropERC20
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    //bytes32("AirdropERC20")
    uint256 private constant MODULE_TYPE = 29586643606843690852087293430700726304775292774467414433021018081583108718592;

    uint256 private constant VERSION = 1;

    uint256 public payeeCount;
    uint256 public processedCount;

    uint256[] public indicesOfFailed;

    mapping(uint256 => AirdropContent) private airdropContent;

    CancelledPayments[] public cancelledPaymentIndices;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor() initializer payable {}

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
    function contractType() external pure returns (bytes32 _type) {
       _type = bytes32(MODULE_TYPE);
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint256 _version) {
        assembly {
            _version := VERSION
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Airdrop logic
    //////////////////////////////////////////////////////////////*/

    ///@notice Lets contract-owner set up an airdrop of ERC20 or native tokens to a list of addresses.
    function addRecipients(AirdropContent[] calldata _contents) external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 len = _contents.length;
        require(len > 0, "No payees provided.");

        uint256 currentCount = payeeCount;
        payeeCount += len;

        uint256 nativeTokenAmount;

        for (uint256 i; i < len;) {
            airdropContent[i + currentCount] = _contents[i];

            if (_contents[i].tokenAddress == CurrencyTransferLib.NATIVE_TOKEN) {
                nativeTokenAmount += _contents[i].amount;
            }

            unchecked {
                ++i;
            }
        }

        require(nativeTokenAmount == msg.value, "Incorrect native token amount");

        emit RecipientsAdded(currentCount, currentCount + len);
    }

    ///@notice Lets contract-owner cancel any pending payments.
    function cancelPendingPayments(uint256 numberOfPaymentsToCancel) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 countOfProcessed = processedCount;
        uint256 nativeTokenAmount;

        // increase processedCount by the specified count -- all pending payments in between will be treated as cancelled.
        uint256 newProcessedCount = countOfProcessed + numberOfPaymentsToCancel;
        require(newProcessedCount <= payeeCount, "Exceeds total payees.");
        processedCount = newProcessedCount;

        CancelledPayments memory range =
            CancelledPayments({startIndex: countOfProcessed, endIndex: newProcessedCount - 1});

        cancelledPaymentIndices.push(range);

        for (uint256 i = countOfProcessed; i < newProcessedCount;) {
            AirdropContent memory content = airdropContent[i];

            if (content.tokenAddress == CurrencyTransferLib.NATIVE_TOKEN) {
                nativeTokenAmount += content.amount;
            }

            unchecked {
                ++i;
            }
        }

        if (nativeTokenAmount > 0) {
            // refund amount to contract admin address
            CurrencyTransferLib.safeTransferNativeToken(msg.sender, nativeTokenAmount);
        }

        emit PaymentsCancelledByAdmin(countOfProcessed, newProcessedCount - 1);
    }

    /// @notice Lets contract-owner send ERC20 or native tokens to a list of addresses.
    function processPayments(uint256 paymentsToProcess) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 totalPayees = payeeCount;
        uint256 countOfProcessed = processedCount;
        uint256 nativeTokenAmount;
        uint256 addedCountOfProcessed = countOfProcessed + paymentsToProcess;

        require(addedCountOfProcessed <= totalPayees, "invalid no. of payments");

        processedCount += paymentsToProcess;

        for (uint256 i = countOfProcessed; i < (addedCountOfProcessed);) {
            AirdropContent memory content = airdropContent[i];
            uint256 amt = content.amount;
            address recipients = content.recipient;
            address owner = content.tokenAddress;
            bool success = _transferCurrencyWithReturnVal(
                owner, content.tokenOwner, recipients, amt
            );

            if (!success) {
                indicesOfFailed.push(i);

                if (owner == CurrencyTransferLib.NATIVE_TOKEN) {
                    nativeTokenAmount += amt;
                }

                success = false;
            }

            emit AirdropPayment(recipients, i, !success);

            unchecked {
                ++i;
            }
        }

        if (nativeTokenAmount > 0) {
            // refund failed payments' amount to contract admin address
            CurrencyTransferLib.safeTransferNativeToken(msg.sender, nativeTokenAmount);
        }
    }

    /**
     *  @notice          Lets contract-owner send ERC20 tokens to a list of addresses.
     *  @dev             The token-owner should approve target tokens to Airdrop contract,
     *                   which acts as operator for the tokens.
     *
     *  @param _contents        List containing recipient, tokenId and amounts to airdrop.
     */
    function airdrop(AirdropContent[] calldata _contents) external payable nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 len = _contents.length;
        uint256 nativeTokenAmount;
        uint256 refundAmount;

        for (uint256 i; i < len;) {
            bool success = _transferCurrencyWithReturnVal(
                _contents[i].tokenAddress, _contents[i].tokenOwner, _contents[i].recipient, _contents[i].amount
            );

            if (_contents[i].tokenAddress == CurrencyTransferLib.NATIVE_TOKEN) {
                nativeTokenAmount += _contents[i].amount;

                if (!success) {
                    refundAmount += _contents[i].amount;
                }
            }

            emit StatelessAirdrop(_contents[i].recipient, _contents[i], !success);

            unchecked {
                ++i;
            }
        }

        require(nativeTokenAmount == msg.value, "Incorrect native token amount");

        if (refundAmount > 0) {
            // refund failed payments' amount to contract admin address
            CurrencyTransferLib.safeTransferNativeToken(msg.sender, refundAmount);
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

        for (uint256 i = startId; i <= endId; ++i) {
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
        for (uint256 i = startId; i <= endId;) {
            contents[idx] = airdropContent[i];
            ++idx;

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Returns all pending airdrop failed.
    function getAllAirdropPaymentsFailed() external view returns (AirdropContent[] memory contents) {
        uint256 count = indicesOfFailed.length;
        contents = new AirdropContent[](count);

        for (uint256 i; i < count;) {
            contents[i] = airdropContent[indicesOfFailed[i]];
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Returns all blocks of cancelled payments as an array of index range.
    function getCancelledPaymentIndices() external view returns (CancelledPayments[] memory) {
        return cancelledPaymentIndices;
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /// @dev Transfers ERC20 tokens and returns a boolean i.e. the status of the transfer.
    function _transferCurrencyWithReturnVal(address _currency, address _from, address _to, uint256 _amount)
        internal
        returns (bool success)
    {
        assembly {
            if iszero(_amount) { success := true }
        }

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            // solhint-disable avoid-low-level-calls
            // slither-disable-next-line low-level-calls
            (success,) = _to.call{value: _amount, gas: 80_000}("");
        } else {
            (bool success_, bytes memory data_) =
                _currency.call(abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _amount));

            success = success_;
            if (!success || (data_.length > 0 && !abi.decode(data_, (bool)))) {
                success = false;

                require(
                    IERC20(_currency).balanceOf(_from) >= _amount
                        && IERC20(_currency).allowance(_from, address(this)) >= _amount,
                    "Not balance or allowance"
                );
            }
        }
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
