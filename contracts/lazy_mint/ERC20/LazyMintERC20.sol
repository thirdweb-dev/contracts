// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import { ILazyMintERC20 } from "./ILazyMintERC20.sol";

// Base
import { Coin } from "../../Coin.sol";

// Access Control + security
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Utils
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Helper interfaces
import { IWETH } from "../../interfaces/IWETH.sol";

contract LazyMintERC20 is ILazyMintERC20, Coin, ReentrancyGuard {

    /// @dev The address of the native token wrapper contract.
    address public immutable nativeTokenWrapper;

    /// @dev The adress that receives all primary sales value.
    address public defaultSaleRecipient;

    /// @dev The % of secondary sales collected as royalties. See EIP 2981.
    uint128 public royaltyBps;

    /// @dev The % of primary sales collected by the contract as fees.
    uint128 public feeBps;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address payable _controlCenter,
        address _trustedForwarder,
        address _nativeTokenWrapper,
        address _saleRecipient,
        uint128 _royaltyBps,
        uint128 _feeBps
    ) 
        Coin(
            _controlCenter,
            _name,
            _symbol,
            _trustedForwarder,
            _contractURI
        )
    {
        // Set the protocol control center        
        nativeTokenWrapper = _nativeTokenWrapper;
        defaultSaleRecipient = _saleRecipient;
        royaltyBps = _royaltyBps;
        feeBps = _feeBps;
    }

        function claim(uint256 _quantity, bytes32[] calldata _proofs) external payable {}

        function setClaimConditions(ClaimCondition[] calldata _conditions) external {}
}