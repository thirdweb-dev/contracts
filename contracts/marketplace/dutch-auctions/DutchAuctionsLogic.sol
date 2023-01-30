// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./DutchAuctionsStorage.sol";

// ====== External imports ======
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// ====== Internal imports ======

import "../../extension/plugin/ERC2771ContextConsumer.sol";

import "../../extension/interface/IPlatformFee.sol";

import "../../extension/plugin/ReentrancyGuardLogic.sol";
import "../../extension/plugin/PermissionsEnumerableLogic.sol";
import { CurrencyTransferLib } from "../../lib/CurrencyTransferLib.sol";
import "prb-math/contracts/PRBMathSD59x18.sol";

contract DutchAuctionsLogic is IDutchAuctions, ReentrancyGuardLogic, ERC2771ContextConsumer {
    using PRBMathSD59x18 for int256;

    /*///////////////////////////////////////////////////////////////
                        Constants / Immutables
    //////////////////////////////////////////////////////////////*/

    /// @dev Only lister role holders can create auctions, when auctions are restricted by lister address.
    bytes32 private constant LISTER_ROLE = keccak256("LISTER_ROLE");
    /// @dev Only assets from NFT contracts with asset role can be auctioned, when auctions are restricted by asset address.
    bytes32 private constant ASSET_ROLE = keccak256("ASSET_ROLE");

    /// @dev The max bps of the contract. So, 10_000 == 100 %
    uint64 public constant MAX_BPS = 10_000;

    /// @dev The address of the native token wrapper contract.
    address private immutable nativeTokenWrapper;

    /*///////////////////////////////////////////////////////////////
                              Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyListerRole() {
        require(PermissionsLogic(address(this)).hasRoleWithSwitch(LISTER_ROLE, _msgSender()), "!LISTER_ROLE");
        _;
    }

    modifier onlyAssetRole(address _asset) {
        require(PermissionsLogic(address(this)).hasRoleWithSwitch(ASSET_ROLE, _asset), "!ASSET_ROLE");
        _;
    }

    /// @dev Checks whether caller is a auction creator.
    modifier onlyAuctionCreator(uint256 _auctionId) {
        DutchAuctionsStorage.Data storage data = DutchAuctionsStorage.dutchAuctionsStorage();

        require(data.auctions[_auctionId].auctionCreator == _msgSender(), "Marketplace: not auction creator.");
        _;
    }

    /// @dev Checks whether an auction exists.
    modifier onlyExistingAuction(uint256 _auctionId) {
        DutchAuctionsStorage.Data storage data = DutchAuctionsStorage.dutchAuctionsStorage();
        require(data.auctions[_auctionId].assetContract != address(0), "Marketplace: auction does not exist.");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            Constructor logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _nativeTokenWrapper) {
        nativeTokenWrapper = _nativeTokenWrapper;
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Auction ERC721 or ERC1155 NFTs.
    function createAuction(AuctionParameters calldata _params)
        external
        onlyListerRole
        onlyAssetRole(_params.assetContract)
        returns (uint256 auctionId)
    {
        auctionId = _getNextAuctionId();
        address auctionCreator = _msgSender();
        TokenType tokenType = _getTokenType(_params.assetContract);

        _validateNewAuction(_params, tokenType);

        Auction memory auction = Auction({
            auctionId: auctionId,
            auctionCreator: auctionCreator,
            assetContract: _params.assetContract,
            tokenId: _params.tokenId,
            quantity: _params.quantity,
            currency: _params.currency,
            initialPrice: _params.initialPrice,
            decayConstant: _params.decayConstant,
            startTimestamp: _params.startTimestamp,
            tokenType: tokenType
        });

        DutchAuctionsStorage.Data storage data = DutchAuctionsStorage.dutchAuctionsStorage();
        data.auctions[auctionId] = auction;

        _transferAuctionTokens(auctionCreator, address(this), auction);

        emit NewAuction(auctionCreator, auctionId, auction);
    }

    /// @dev Cancels an auction.
    function cancelAuction(uint256 _auctionId) external onlyExistingAuction(_auctionId) onlyAuctionCreator(_auctionId) {
        DutchAuctionsStorage.Data storage data = DutchAuctionsStorage.dutchAuctionsStorage();
        Auction memory _targetAuction = data.auctions[_auctionId];

        // check conditions here

        delete data.auctions[_auctionId];

        _transferAuctionTokens(address(this), _targetAuction.auctionCreator, _targetAuction);

        emit AuctionClosed(_targetAuction.auctionId, _msgSender(), true, _targetAuction.auctionCreator, address(0));
    }

    ///@notice purchase tokens from the GDA
    function purchaseTokens(uint256 _auctionId) public payable {
        uint256 cost = purchasePrice(_auctionId);

        require(msg.value >= cost, "Marketplace: Insufficient payment");

        //transfer tokens here

        //refund extra payment
        uint256 refund = msg.value - cost;
        (bool sent, ) = msg.sender.call{ value: refund }("");
        if (!sent) {
            // revert UnableToRefund();
        }
    }

    ///@notice calculate purchase price using exponential discrete GDA formula
    function purchasePrice(uint256 _auctionId) public view returns (uint256) {
        DutchAuctionsStorage.Data storage data = DutchAuctionsStorage.dutchAuctionsStorage();
        Auction memory _targetAuction = data.auctions[_auctionId];

        int256 timeSinceStart = int256(block.timestamp).fromInt() - int256(_targetAuction.startTimestamp);

        int256 den = int256(_targetAuction.decayConstant).mul(timeSinceStart).exp();
        int256 totalCost = int256(_targetAuction.initialPrice).div(den);
        //total cost is already in terms of wei so no need to scale down before
        //conversion to uint. This is due to the fact that the original formula gives
        //price in terms of ether but we scale up by 10^18 during computation
        //in order to do fixed point math.
        return uint256(totalCost);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    function totalAuctions() external view returns (uint256) {
        DutchAuctionsStorage.Data storage data = DutchAuctionsStorage.dutchAuctionsStorage();
        return data.totalAuctions;
    }

    function getAuction(uint256 _auctionId)
        external
        view
        onlyExistingAuction(_auctionId)
        returns (Auction memory _auction)
    {
        DutchAuctionsStorage.Data storage data = DutchAuctionsStorage.dutchAuctionsStorage();
        _auction = data.auctions[_auctionId];
    }

    function getAllAuctions(uint256 _startId, uint256 _endId) external view returns (Auction[] memory _allAuctions) {
        DutchAuctionsStorage.Data storage data = DutchAuctionsStorage.dutchAuctionsStorage();
        require(_startId <= _endId && _endId < data.totalAuctions, "invalid range");

        Auction[] memory _auctions = new Auction[](_endId - _startId + 1);
        uint256 _auctionCount;

        for (uint256 i = _startId; i <= _endId; i += 1) {
            uint256 j = i - _startId;
            _auctions[j] = data.auctions[i];
            if (_auctions[j].assetContract != address(0)) {
                _auctionCount += 1;
            }
        }

        _allAuctions = new Auction[](_auctionCount);
        uint256 index = 0;
        uint256 count = _auctions.length;
        for (uint256 i = 0; i < count; i += 1) {
            if (_auctions[i].assetContract != address(0)) {
                _allAuctions[index++] = _auctions[i];
            }
        }
    }

    function getAllValidAuctions(uint256 _startId, uint256 _endId)
        external
        view
        returns (Auction[] memory _validAuctions)
    {
        DutchAuctionsStorage.Data storage data = DutchAuctionsStorage.dutchAuctionsStorage();
        require(_startId <= _endId && _endId < data.totalAuctions, "invalid range");

        Auction[] memory _auctions = new Auction[](_endId - _startId + 1);
        uint256 _auctionCount;

        for (uint256 i = _startId; i <= _endId; i += 1) {
            uint256 j = i - _startId;
            _auctions[j] = data.auctions[i];
            if (_auctions[j].startTimestamp <= block.timestamp && _auctions[j].assetContract != address(0)) {
                _auctionCount += 1;
            }
        }

        _validAuctions = new Auction[](_auctionCount);
        uint256 index = 0;
        uint256 count = _auctions.length;
        for (uint256 i = 0; i < count; i += 1) {
            if (_auctions[i].startTimestamp <= block.timestamp && _auctions[i].assetContract != address(0)) {
                _validAuctions[index++] = _auctions[i];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the next auction Id.
    function _getNextAuctionId() internal returns (uint256 id) {
        DutchAuctionsStorage.Data storage data = DutchAuctionsStorage.dutchAuctionsStorage();
        id = data.totalAuctions;
        data.totalAuctions += 1;
    }

    /// @dev Returns the interface supported by a contract.
    function _getTokenType(address _assetContract) internal view returns (TokenType tokenType) {
        if (IERC165(_assetContract).supportsInterface(type(IERC1155).interfaceId)) {
            tokenType = TokenType.ERC1155;
        } else if (IERC165(_assetContract).supportsInterface(type(IERC721).interfaceId)) {
            tokenType = TokenType.ERC721;
        } else {
            revert("Marketplace: auctioned token must be ERC1155 or ERC721.");
        }
    }

    /// @dev Checks whether the auction creator owns and has approved marketplace to transfer auctioned tokens.
    function _validateNewAuction(AuctionParameters memory _params, TokenType _tokenType) internal view {
        require(_params.quantity > 0, "Marketplace: auctioning zero quantity.");
        require(_params.quantity == 1 || _tokenType == TokenType.ERC1155, "Marketplace: auctioning invalid quantity.");
        require(_params.startTimestamp + 60 minutes >= block.timestamp, "Marketplace: invalid timestamps.");

        // add more checks here
    }

    /// @dev Transfers tokens for auction.
    function _transferAuctionTokens(
        address _from,
        address _to,
        Auction memory _auction
    ) internal {}

    /// @dev Pays out stakeholders in auction.
    function _payout(
        address _payer,
        address _payee,
        address _currencyToUse,
        uint256 _totalPayoutAmount,
        Auction memory _targetAuction
    ) internal {}
}
