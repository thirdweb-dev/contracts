// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../utils/UserOperation.sol";
import "../../interface/IAccount.sol";

interface IModularAccount is IAccount {
    event ValidatorUpdated(address indexed priorValidator, address indexed newValidator);

    function execute(
        address _target,
        uint256 _value,
        bytes calldata _calldata
    ) external;

    function executeBatch(
        address[] calldata _target,
        uint256[] calldata _value,
        bytes[] calldata _calldata
    ) external;

    function setValidator(address _validator) external;

    function updateSignerOnFactory(address _signer, bool _status) external;
}
