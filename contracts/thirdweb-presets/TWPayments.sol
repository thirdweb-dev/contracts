// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./TWCurrencyTransfers.sol";
import { ThirdwebFees } from "../ThirdwebFees.sol";

contract TWPayments is IERC2981, Initializable, TWCurrencyTransfers {
    /// @dev Max bps in the thirdweb system
    uint256 public constant MAX_BPS = 10_000;

    ThirdwebFees public immutable thirdwebFees;

    /// @dev The recipient of who gets the royalty.
    address public paymentsRecipient;

    /// @dev The percentage of royalty how much royalty in basis points.
    uint96 public royaltyBps;

    /// @dev Emitted when the royalty recipient or fee bps is updated
    event NewPaymentsRecipient(address newPaymentsRecipient);
    event RoyaltyUpdated(uint96 newRoyaltyBps);
    event EtherReceived(address sender, uint256 amount);
    event FundsWithdrawn(
        address indexed paymentReceiver,
        address feeRecipient,
        uint256 totalAmount,
        uint256 feeCollected
    );

    constructor(address _nativeTokenWrapper, address _thirdwebFees) TWCurrencyTransfers(_nativeTokenWrapper) {
        thirdwebFees = ThirdwebFees(_thirdwebFees);
    }

    /// @dev Initializes the contract, like a constructor.
    function __TWPayments_init(address _receiver, uint96 _royaltyBps) internal onlyInitializing {
        __TWPayments_init_unchained(_receiver, _royaltyBps);
    }

    function __TWPayments_init_unchained(address _receiver, uint96 _royaltyBps) internal onlyInitializing {
        paymentsRecipient = _receiver;
        royaltyBps = _royaltyBps;
    }

    function withdrawFunds(address _currency) external {
        address recipient = paymentsRecipient;
        address feeRecipient = thirdwebFees.getRoyaltyFeeRecipient(address(this));

        uint256 totalTransferAmount = _currency == NATIVE_TOKEN
            ? address(this).balance
            : IERC20(_currency).balanceOf(_currency);
        uint256 fees = (totalTransferAmount * thirdwebFees.getRoyaltyFeeBps(address(this))) / MAX_BPS;

        transferCurrency(_currency, address(this), recipient, totalTransferAmount - fees);
        transferCurrency(_currency, address(this), feeRecipient, fees);

        emit FundsWithdrawn(recipient, feeRecipient, totalTransferAmount, fees);
    }

    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    /**
     * @dev For setting NFT royalty recipient.
     *
     * @param _paymentsRecipient The address of which the payments goes to.
     */
    function _setPaymentsRecipient(address _paymentsRecipient) internal {
        paymentsRecipient = _paymentsRecipient;
        emit NewPaymentsRecipient(_paymentsRecipient);
    }

    /**
     * @dev For setting royalty basis points.
     *
     * @param _royaltyBps the basis points of royalty. 10_000 = 100%.
     */
    function _setRoyaltyBps(uint256 _royaltyBps) internal {
        require(_royaltyBps <= 10_000, "exceed royalty bps");
        royaltyBps = uint96(_royaltyBps);
        emit RoyaltyUpdated(uint96(_royaltyBps));
    }

    /// @dev See EIP-2981
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = address(this);
        royaltyAmount = (salePrice * royaltyBps) / 10_000;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC2981).interfaceId;
    }
}