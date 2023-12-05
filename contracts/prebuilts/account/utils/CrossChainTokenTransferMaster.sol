// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
// Account Abstraction setup for smart wallets.
import { EntryPoint, IEntryPoint } from "contracts/prebuilts/account/utils/Entrypoint.sol";
import { UserOperation } from "contracts/prebuilts/account/utils/UserOperation.sol";

// Target
import { IAccountPermissions } from "contracts/extension/interface/IAccountPermissions.sol";
import { AccountFactory } from "contracts/prebuilts/account/non-upgradeable/AccountFactory.sol";
import { Account as SimpleAccount } from "contracts/prebuilts/account/non-upgradeable/Account.sol";

import { IERC20 } from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";

//import cross chain contract contract
import "./CrossChainTokenTransfer.sol";

contract CrossChainTokenTransferMaster {
    //flow for native payment
    function getEstimate(
        CrossChainTokenTransfer _crossChainContract,
        uint64 _destinationChainSelector,
        address _receiver,
        address _token,
        uint256 _amount
    ) external view returns (uint estimate) {
        //call the estimate function
        estimate = _crossChainContract.estimateNative(_destinationChainSelector, _receiver, _token, _amount);
    }

    function initiateTokenTransferPayNative(
        CrossChainTokenTransfer _crossChainContract,
        uint64 _destinationChainSelector,
        address _receiver,
        address _token,
        uint256 _amount
    ) external payable {
        //approve token amount
        IERC20(_token).approve(address(_crossChainContract), _amount);

        //call transfer function with value
        (bool success, ) = address(_crossChainContract).call{ value: msg.value }(
            abi.encodeWithSignature(
                "transferTokensPayNative(uint64 , address, address ,address , uint256 ,uint256 )",
                _destinationChainSelector,
                _receiver,
                msg.sender,
                _token,
                _amount,
                _amount
            )
        );

        require(success, "Cross chain token transfer initiation failed");
    }
}
