// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

// Tokens
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Access Control
import "@openzeppelin/contracts/access/Ownable.sol";

// Meta transactions
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

// Protocol control center.
import { ProtocolControl } from "./ProtocolControl.sol";

// Royalties
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract NFTCollection is ERC1155PresetMinterPauser, ERC2771Context, IERC2981 {
    /// @dev The protocol control center.
    ProtocolControl internal controlCenter;

    /// @dev The token Id of the NFT to mint.
    uint256 public nextTokenId;

    /// @dev NFT sale royalties -- see EIP 2981
    uint256 public nftRoyaltyBps;

    /// @dev Collection level metadata.
    string public _contractURI;

    enum UnderlyingType {
        None,
        ERC20,
        ERC721
    }

    struct NftInfo {
        address creator;
        string uri;
        uint256 supply;
        UnderlyingType underlyingType;
    }

    struct ERC721Wrapped {
        address nftContract;
        uint256 nftTokenId;
    }

    struct ERC20Wrapped {
        address tokenContract;
        uint256 shares;
        uint256 underlyingTokenAmount;
    }

    /// @notice Events.
    event NativeNfts(address indexed creator, uint256[] nftIds, string[] nftURIs, uint256[] nftSupplies);
    event ERC721WrappedNft(
        address indexed creator,
        address indexed nftContract,
        uint256 nftTokenId,
        uint256 nativeNftTokenId,
        string nativeNftURI
    );
    event ERC721Redeemed(
        address indexed redeemer,
        address indexed nftContract,
        uint256 nftTokenId,
        uint256 nativeNftTokenId
    );
    event ERC20WrappedNfts(
        address indexed creator,
        address indexed tokenContract,
        uint256 tokenAmount,
        uint256 nftsMinted,
        string nftURI
    );
    event ERC20Redeemed(
        address indexed redeemer,
        address indexed tokenContract,
        uint256 tokenAmountReceived,
        uint256 nftAmountRedeemed
    );

    event NftRoyaltyUpdated(uint256 royaltyBps);

    event NftLevelUpdated(uint tokenId, uint newMaxLevel, string levelURI);

    /// @dev NFT tokenId => NFT state.
    mapping(uint256 => NftInfo) public nftInfo;

    /// @dev NFT tokenId => max level of NFT
    mapping(uint => uint) public maxLevelOfNft;

    /// @dev NFT tokenId => owner address => NFT level => owner balance.
    mapping(uint => mapping(address => mapping(uint => uint))) public balanceByLevel;

    /// @dev NFT tokenId => NFT level => total supply of NFTs at that level.
    mapping(uint => mapping(uint => string)) public uriByLevel;

    /// @dev NFT tokenId => NFT level => total supply of NFTs at that level.
    mapping(uint => mapping(uint => uint)) public totalSupplyOfLevel;

    /// @dev NFT tokenId => Underlying ERC721 NFT state.
    mapping(uint256 => ERC721Wrapped) public erc721WrappedNfts;

    /// @dev NFT tokenId => Underlying ERC20 NFT state.
    mapping(uint256 => ERC20Wrapped) public erc20WrappedNfts;

    /// @dev Checks whether the protocol is paused.
    modifier onlyUnpausedProtocol() {
        require(!controlCenter.systemPaused(), "NFT: The protocol is paused.");
        _;
    }

    /// @dev Checks whether the protocol is paused.
    modifier onlyProtocolAdmin() {
        require(
            controlCenter.hasRole(controlCenter.PROTOCOL_ADMIN(), _msgSender()),
            "NFT: only a protocol admin can call this function."
        );
        _;
    }

    constructor(
        address payable _controlCenter,
        address _trustedForwarder,
        string memory _uri
    ) ERC1155PresetMinterPauser(_uri) ERC2771Context(_trustedForwarder) {
        // Set the protocol control center
        controlCenter = ProtocolControl(_controlCenter);

        // Set contract URI
        _contractURI = _uri;
    }

    /// @notice Create native ERC 1155 NFTs.
    function createNativeNfts(string[] calldata _nftURIs, uint256[] calldata _nftSupplies)
        public
        onlyUnpausedProtocol
        returns (uint256[] memory nftIds)
    {
        require(_nftURIs.length == _nftSupplies.length, "NFT: Must specify equal number of config values.");
        require(_nftURIs.length > 0, "NFT: Must create at least one NFT.");

        // Get tokenIds.
        nftIds = new uint256[](_nftURIs.length);

        uint id = nextTokenId;
        uint initialLevel = 0;
        address creatorOfNfts = _msgSender();
        uint[] memory levels = new uint[](_nftURIs.length);

        // Store NFT state for each NFT.
        for (uint256 i = 0; i < _nftURIs.length; i++) {
            // Store NFT tokenId
            nftIds[i] = id;

            // Update NFT data at global level.
            nftInfo[id] = NftInfo({
                creator: creatorOfNfts,
                uri: _nftURIs[i],
                supply: _nftSupplies[i],
                underlyingType: UnderlyingType.None
            });

            // Update NFT supply by level
            totalSupplyOfLevel[id][initialLevel] = _nftSupplies[i];

            // Update NFT balance by level
            balanceByLevel[id][creatorOfNfts][initialLevel] = _nftSupplies[i];

            // Update NFT URI by level
            uriByLevel[id][initialLevel] = _nftURIs[i];

            // Update vars
            levels[i] = initialLevel;
            id += 1;
        }

        // Update the global tokenId counter.
        nextTokenId = id;

        // Mint NFTs to `_msgSender()`
        mintBatch(_msgSender(), nftIds, _nftSupplies, abi.encode(levels));

        emit NativeNfts(_msgSender(), nftIds, _nftURIs, _nftSupplies);
    }

    /// @dev Creates packs with NFT.
    function createPackAtomic(
        address _pack,
        string[] calldata _nftURIs,
        uint256[] calldata _nftSupplies,
        string calldata _packURI,
        uint256 _secondsUntilOpenStart,
        uint256 _secondsUntilOpenEnd,
        uint256 _nftsPerOpen
    ) external onlyUnpausedProtocol {
        uint256[] memory nftIds = createNativeNfts(_nftURIs, _nftSupplies);

        bytes memory args = abi.encode(_packURI, _secondsUntilOpenStart, _secondsUntilOpenEnd, _nftsPerOpen);
        safeBatchTransferFrom(_msgSender(), _pack, nftIds, _nftSupplies, args);
    }

    /// @dev Lets a protocol admin update the the next level of an NFT.
    function updateMaxLevelOfNft(uint _tokenId, string calldata _levelURI) external onlyProtocolAdmin {
        
        require(
            _tokenId < nextTokenId,
            "NFTCollection: cannot update the level of a non existent NFT."
        );

        // Update max level of NFT
        uint level = ++maxLevelOfNft[_tokenId];

        // Update URI of level
        uriByLevel[_tokenId][level] = _levelURI;

        emit NftLevelUpdated(_tokenId, level, _levelURI);
    }

    /// @dev Let NFT owner level up their NFTs (as many as eligible)
    function levelUpNFTs(uint _tokenId, uint _amount, uint _fromLevel, uint _toLevel) external {
        uint maxLevel = maxLevelOfNft[_tokenId];

        require(
            _fromLevel < maxLevel && _toLevel <= maxLevel,
            "NFTCollection: invalid levels provided."
        );

        require(
            balanceByLevel[_tokenId][_msgSender()][_fromLevel] >= _amount,
            "NFTCollection: not enough NFTs of provided level, owned."
        );

        /**
         * NEED eligibility condition for an aditional require check to see if user is eligible to level up `_amount` of 
         * NFT from `_fromLevel` to `_toLevel`
         */

        // Update balances by level
        balanceByLevel[_tokenId][_msgSender()][_fromLevel] -= _amount;
        balanceByLevel[_tokenId][_msgSender()][_toLevel] += _amount;
    }

    /// @dev Lets a protocol admin update the royalties paid on pack sales.
    function setNftRoyaltyBps(uint256 _royaltyBps) external onlyProtocolAdmin {
        require(_royaltyBps < controlCenter.MAX_BPS(), "NFT: Bps provided must be less than 10,000");

        nftRoyaltyBps = _royaltyBps;

        emit NftRoyaltyUpdated(_royaltyBps);
    }

    /// @dev Sets contract URI for the storefront-level metadata of the contract.
    function setContractURI(string calldata _URI) external onlyProtocolAdmin {
        _contractURI = _URI;
    }

    /// @dev Wraps an ERC721 NFT as ERC1155 NFTs.
    function wrapERC721(
        address _nftContract,
        uint256 _tokenId,
        string calldata _nftURI
    ) external onlyUnpausedProtocol {
        require(IERC721(_nftContract).ownerOf(_tokenId) == _msgSender(), "NFT: Only the owner of the NFT can wrap it.");
        require(
            IERC721(_nftContract).getApproved(_tokenId) == address(this) ||
                IERC721(_nftContract).isApprovedForAll(_msgSender(), address(this)),
            "NFT: Must approve the contract to transfer the NFT."
        );

        // Transfer the NFT to this contract.
        IERC721(_nftContract).safeTransferFrom(_msgSender(), address(this), _tokenId);

        // Mint NFTs to `_msgSender()`
        uint[1] memory level = [uint256(0)];
        mint(_msgSender(), nextTokenId, 1, abi.encode(level));

        // Store nft state.
        nftInfo[nextTokenId] = NftInfo({
            creator: _msgSender(),
            uri: _nftURI,
            supply: 1,
            underlyingType: UnderlyingType.ERC721
        });

        // Map the nft tokenId to the underlying NFT
        erc721WrappedNfts[nextTokenId] = ERC721Wrapped({ nftContract: _nftContract, nftTokenId: _tokenId });

        emit ERC721WrappedNft(_msgSender(), _nftContract, _tokenId, nextTokenId, _nftURI);

        nextTokenId++;
    }

    /// @dev Lets the nft owner redeem their ERC721 NFT.
    function redeemERC721(uint256 _nftId) external {
        require(balanceOf(_msgSender(), _nftId) > 0, "NFT: Cannot redeem an NFT you do not own.");

        // Burn the ERC1155 NFT token
        _burn(_msgSender(), _nftId, 1);

        // Transfer the NFT to `_msgSender()`
        IERC721(erc721WrappedNfts[_nftId].nftContract).safeTransferFrom(
            address(this),
            _msgSender(),
            erc721WrappedNfts[_nftId].nftTokenId
        );

        emit ERC721Redeemed(
            _msgSender(),
            erc721WrappedNfts[_nftId].nftContract,
            erc721WrappedNfts[_nftId].nftTokenId,
            _nftId
        );
    }

    /// @dev Wraps ERC20 tokens as ERC1155 NFTs.
    function wrapERC20(
        address _tokenContract,
        uint256 _tokenAmount,
        uint256 _numOfNftsToMint,
        string calldata _nftURI
    ) external onlyUnpausedProtocol {
        require(
            IERC20(_tokenContract).balanceOf(_msgSender()) >= _tokenAmount,
            "NFT: Must own the amount of tokens that are being wrapped."
        );

        require(
            IERC20(_tokenContract).allowance(_msgSender(), address(this)) >= _tokenAmount,
            "NFT: Must approve this contract to transfer ERC20 tokens."
        );

        require(
            IERC20(_tokenContract).transferFrom(_msgSender(), address(this), _tokenAmount),
            "Failed to transfer ERC20 tokens."
        );

        // Mint NFTs to `_msgSender()`
        uint[1] memory level = [uint256(0)];
        mint(_msgSender(), nextTokenId, _numOfNftsToMint, abi.encode(level));

        nftInfo[nextTokenId] = NftInfo({
            creator: _msgSender(),
            uri: _nftURI,
            supply: _numOfNftsToMint,
            underlyingType: UnderlyingType.ERC20
        });

        erc20WrappedNfts[nextTokenId] = ERC20Wrapped({
            tokenContract: _tokenContract,
            shares: _numOfNftsToMint,
            underlyingTokenAmount: _tokenAmount
        });

        emit ERC20WrappedNfts(_msgSender(), _tokenContract, _tokenAmount, _numOfNftsToMint, _nftURI);

        nextTokenId++;
    }

    /// @dev Lets the nft owner redeem their ERC20 tokens.
    function redeemERC20(uint256 _nftId, uint256 _amount) external {
        require(balanceOf(_msgSender(), _nftId) >= _amount, "NFT: Cannot redeem an NFT you do not own.");

        // Burn the nft
        _burn(_msgSender(), _nftId, _amount);

        // Get the ERC20 token amount to distribute
        uint256 amountToDistribute = (erc20WrappedNfts[_nftId].underlyingTokenAmount * _amount) /
            erc20WrappedNfts[_nftId].shares;

        // Transfer the ERC20 tokens to `_msgSender()`
        require(
            IERC20(erc20WrappedNfts[_nftId].tokenContract).transfer(_msgSender(), amountToDistribute),
            "NFT: Failed to transfer ERC20 tokens."
        );

        emit ERC20Redeemed(_msgSender(), erc20WrappedNfts[_nftId].tokenContract, amountToDistribute, _amount);
    }

    /// @dev Updates a token's total supply.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // Decrease total supply if tokens are being burned.
        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                nftInfo[ids[i]].supply -= amounts[i];
            }
        }

        // Update balances by level
        uint[] memory levels = abi.decode(data, (uint[]));
        require(
            levels.length == ids.length,
            "NFTCollection: Must specify levels for all tokens."
        );
        
        for (uint256 i = 0; i < ids.length; i++) {
            uint level = levels[i];
            uint id = ids[i];
            uint amount = amounts[i];

            require(
                balanceByLevel[id][from][level] >= amount,
                "NFTCollection: Not enough NFTs of the level provided, owned."
            );

            balanceByLevel[id][from][level] -= amount;
            balanceByLevel[id][to][level] += amount;
        }
    }

    /// @dev See EIP 2918
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = nftInfo[tokenId].creator;
        royaltyAmount = (salePrice * nftRoyaltyBps) / controlCenter.MAX_BPS();
    }

    /// @dev See EIP 1155
    function uri(uint256 _nftId) public view override returns (string memory) {
        return nftInfo[_nftId].uri;
    }

    /// @dev Alternative function to return a token's URI
    function tokenURI(uint256 _nftId) public view returns (string memory) {
        return nftInfo[_nftId].uri;
    }

    /// @dev Returns the URI for the storefront-level metadata of the contract.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @dev Returns the creator of an NFT
    function creator(uint256 _nftId) external view returns (address) {
        return nftInfo[_nftId].creator;
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
