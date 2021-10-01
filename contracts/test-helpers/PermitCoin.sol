// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract PermitCoin is ERC20Permit {

    constructor() ERC20Permit("name") ERC20("name", "symbol") {}

    /// @dev Free mint
    function freeMint(uint amount) external {
        _mint(_msgSender(), amount);
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {
        super.permit(owner, spender, value, deadline, v, r, s);
    }
}