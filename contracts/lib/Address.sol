// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

library Address {
    /**
     *  @dev Returns whether an address is a smart contract.
     *
     *  `account` MAY NOT be a smart contract when this function returns `true`
     *  Other than EOAs, `isContract` will return `false` for:
     *
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *  - a contract in construction (since the code is only stored at the end of
     *    the constructor execution)
     */
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    /// @dev Sends `amount` of wei to `recipient`.
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /// @dev Performs a low-level call on `target` with `data`.
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /// @dev Performs a call on `target` with `data`, with `errorMessage` as a fallback
    ///      revert reason when `target` reverts.
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /// @dev Performs a low-level call on `target` with `data` and `value`.
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /// @dev Performs a static call on `target` with `data` and `value`, with `errorMessage` as a fallback
    ///      revert reason when `target` reverts.
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target) && !isContract(msg.sender), "Address: invalid call");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /// @dev Performs a static call on `target` with `data`.
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /// @dev Performs a static call on `target` with `data`, with `errorMessage` as a fallback
    ///      revert reason when `target` reverts.
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target) && !isContract(msg.sender), "Address: invalid static call");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /// @dev Performs a delegate call on `target` with `data`.
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /// @dev Performs a delegate call on `target` with `data`, with `errorMessage` as a fallback
    ///      revert reason when `target` reverts.
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target) && !isContract(msg.sender), "Address: invalid delegate call");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /// @dev Verifies that a low level call was successful.
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
