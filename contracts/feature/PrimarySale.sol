// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IThirdwebPrimarySale.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

contract PrimarySale is IThirdwebPrimarySale, AccessControlEnumerableUpgradeable {
    
    /// @dev The address that receives all primary sales value.
    address private recipient;

    function primarySaleRecipient() public view returns (address) {
        return recipient;
    }

    /// @dev Lets a contract admin set the recipient for all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        recipient = _saleRecipient;
        emit PrimarySaleRecipientUpdated(_saleRecipient);
    }
}