// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IThirdwebToken.sol";

interface IThirdwebNFT is IThirdwebToken {
    
    /// @dev The thirdweb contract with fee related information.
    function thirdwebFees() external view returns (string memory);
}