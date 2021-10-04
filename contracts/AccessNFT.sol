// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Tokens
import "./openzeppelin-presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Meta transactions
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

// Protocol control center.
import { ProtocolControl } from "./ProtocolControl.sol";

// Royalties
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract AccessNFT is ERC1155PresetMinterPauser, IERC1155Receiver, ERC2771Context, IERC2981 {
    /// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    /// @dev Whether transfers on tokens are restricted.
    bool public isRestrictedTransfer;

    /// @dev The protocol control center.
    ProtocolControl internal controlCenter;

    /// @dev The token Id of the NFT to mint.
    uint256 public nextTokenId;

    /// @dev NFT sale royalties -- see EIP 2981
    uint256 public royaltyBps;

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
        bool isAccess;
        uint256 accessNftId;
        UnderlyingType underlyingType;
    }

    /// @dev Emmitted when Access NFTs are created.
    event AccessNFTsCreated(
        address indexed creator,
        uint256[] nftIds,
        string[] nftURIs,
        uint256[] acessNftIds,
        string[] accessNftURIs,
        uint256[] nftSupplies
    );
    event AccessNFTRedeemed(
        address indexed redeemer,
        uint256 indexed nftTokenId,
        uint256 indexed accessNftId,
        uint256 amount
    );
    event RoyaltyUpdated(uint256 royaltyBps);
    event LastRedeemTimeUpdated(uint accessNftId, address creator, uint lastTimeToRedeem);

    /// @dev NFT tokenId => NFT state.
    mapping(uint256 => NftInfo) public nftInfo;

    /// @dev Access NFT tokenId => final redemption timestamp.
    mapping(uint256 => uint256) public lastTimeToRedeem;

    /// @dev Checks whether the protocol is paused.
    modifier onlyUnpausedProtocol() {
        require(!controlCenter.systemPaused(), "AccessNFT: The protocol is paused.");
        _;
    }

    /// @dev Checks whether the protocol is paused.
    modifier onlyProtocolAdmin() {
        require(
            controlCenter.hasRole(controlCenter.PROTOCOL_ADMIN(), _msgSender()),
            "AccessNFT: only a protocol admin can call this function."
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

        _setupRole(TRANSFER_ROLE, _msgSender());
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC1155PresetMinterPauser, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC2981).interfaceId;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @dev Creates pack on receiving ERC 1155 reward tokens
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /// @notice Create native ERC 1155 NFTs.
    function createAccessNfts(
        string[] calldata _nftURIs,
        string[] calldata _accessNftURIs,
        uint256[] calldata _nftSupplies
    ) public onlyUnpausedProtocol returns (uint256[] memory nftIds) {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "AccessNFT: Only accounts with MINTER_ROLE can call this function."
        );
        require(
            _nftURIs.length == _nftSupplies.length && _nftURIs.length == _accessNftURIs.length,
            "AccessNFT: Must specify equal number of config values."
        );
        require(_nftURIs.length > 0, "AccessNFT: Must create at least one NFT.");

        // Get tokenIds.
        nftIds = new uint256[](_nftURIs.length);
        uint256[] memory accessNftIds = new uint256[](_nftURIs.length);

        uint256 id = nextTokenId;

        // Store NFT state for each NFT.
        for (uint256 i = 0; i < _nftURIs.length; i++) {
            // Store Access NFT tokenId
            accessNftIds[i] = id;

            // Store Access NFT info
            nftInfo[id] = NftInfo({
                creator: _msgSender(),
                uri: _accessNftURIs[i],
                supply: _nftSupplies[i],
                isAccess: true,
                accessNftId: 0,
                underlyingType: UnderlyingType.None
            });

            // Update id
            id += 1;

            // Store NFT tokenId
            nftIds[i] = id;

            // Store NFT info
            nftInfo[id] = NftInfo({
                creator: _msgSender(),
                uri: _nftURIs[i],
                supply: _nftSupplies[i],
                isAccess: false,
                accessNftId: (id - 1),
                underlyingType: UnderlyingType.None
            });

            // Update id
            id += 1;
        }

        nextTokenId = id;

        // Mint Access NFTs to contract
        _mintBatch(address(this), accessNftIds, _nftSupplies, "");

        // Mint NFTs to `_msgSender()`
        _mintBatch(_msgSender(), nftIds, _nftSupplies, "");

        emit AccessNFTsCreated(_msgSender(), nftIds, _nftURIs, accessNftIds, _accessNftURIs, _nftSupplies);
    }

    /// @dev Creates packs with NFT.
    function createAccessPack(
        address _pack,
        string[] calldata _nftURIs,
        string[] calldata _accessNftURIs,
        uint256[] calldata _nftSupplies,
        string calldata _packURI,
        uint256 _secondsUntilOpenStart,
        uint256 _secondsUntilOpenEnd,
        uint256 _nftsPerOpen
    ) external onlyUnpausedProtocol {
        uint256[] memory nftIds = createAccessNfts(_nftURIs, _accessNftURIs, _nftSupplies);

        bytes memory args = abi.encode(_packURI, _secondsUntilOpenStart, _secondsUntilOpenEnd, _nftsPerOpen);
        safeBatchTransferFrom(_msgSender(), _pack, nftIds, _nftSupplies, args);
    }

    /// @dev Lets an NFT holder redeem the underlying Access NFT.
    function redeemAccess(uint256 _tokenId, uint256 _amount) external onlyUnpausedProtocol {
        require(!nftInfo[_tokenId].isAccess, "AccessNFT: This token is not redeemable for access.");

        // Get redeemer
        address redeemer = _msgSender();

        require(balanceOf(redeemer, _tokenId) >= _amount, "AccessNFT: Cannot redeem more NFTs than owned.");

        // Burn NFTs of the 'unredeemed' state.
        burn(_msgSender(), _tokenId, _amount);

        // Get access nft Id
        uint256 accessNftId = nftInfo[_tokenId].accessNftId;

        require(
            block.timestamp <= lastTimeToRedeem[accessNftId] || lastTimeToRedeem[accessNftId] == 0,
            "AccessNFT: Window to redeem access has closed."
        );

        // Transfer Access NFTs to redeemer
        this.safeTransferFrom(address(this), redeemer, accessNftId, _amount, "");

        emit AccessNFTRedeemed(redeemer, _tokenId, accessNftId, _amount);
    }

    /// @dev Lets an Access NFT creator set a limit for when the reward can be redeemed.
    function setLastTimeToRedeem(uint _tokenId, uint _secondsUntilRedeem) external {
        require(
            _msgSender() == nftInfo[_tokenId].creator,
            "AccessNFT: only the creator can call this function."
        );
        require(
            nftInfo[_tokenId].isAccess,
            "AccessNFT: can set redeem time for only Access NFTs."
        );
        
        uint lastTimeToRedeemNFT = _secondsUntilRedeem == 0 ? type(uint).max : block.timestamp + _secondsUntilRedeem;
        lastTimeToRedeem[_tokenId] = lastTimeToRedeemNFT;

        emit LastRedeemTimeUpdated(_tokenId, _msgSender(), lastTimeToRedeemNFT);
    }

    /// @dev Lets a protocol admin update the royalties paid on pack sales.
    function setRoyaltyBps(uint256 _royaltyBps) external onlyProtocolAdmin {
        require(
            _royaltyBps < (controlCenter.MAX_BPS() + controlCenter.MAX_PROVIDER_FEE_BPS()),
            "NFT: Bps provided must be less than 9,000"
        );

        royaltyBps = _royaltyBps;

        emit RoyaltyUpdated(_royaltyBps);
    }

    /// @dev Sets contract URI for the storefront-level metadata of the contract.
    function setContractURI(string calldata _URI) external onlyProtocolAdmin {
        _contractURI = _URI;
    }

    /// @dev Lets a protocol admin restrict token transfers.
    function setRestrictedTransfer(bool _restrictedTransfer) external onlyProtocolAdmin {
        isRestrictedTransfer = _restrictedTransfer;
    }

    /**
     * @dev See {ERC1155-_mint}.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        super._mint(account, id, amount, data);
        nftInfo[id].supply += amount;
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(id < nextTokenId, "NFTCollection: cannot call this fn for creating new NFTs.");
        require(nftInfo[id].underlyingType == UnderlyingType.None, "NFTCollection: cannot freely mint more of ERC20 or ERC721.");
        
        super.mint(to, id, amount, data);
    }

    /**
     * @dev See {ERC1155-_mintBatch}.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._mintBatch(to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            nftInfo[ids[i]].supply += amounts[i];
        }
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        
        bool validIds = true;
        bool validTokenType = true;
        
        for (uint256 i = 0; i < ids.length; ++i) {
            if(ids[i] >= nextTokenId && validIds) {
                validIds = false;
            }

            if(nftInfo[ids[i]].underlyingType != UnderlyingType.None && validTokenType) {
                validTokenType = false;
            }        
        }

        require(validIds, "NFTCollection: cannot call this fn for creating new NFTs.");
        require(validTokenType, "NFTCollection: cannot freely mint more of ERC20 or ERC721.");


        super.mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev See {ERC1155-_burn}.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        super._burn(account, id, amount);
        nftInfo[id].supply -= amount;
    }

    /**
     * @dev See {ERC1155-_burnBatch}.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        super._burnBatch(account, ids, amounts);
        for (uint256 i = 0; i < ids.length; ++i) {
            nftInfo[ids[i]].supply -= amounts[i];
        }
    }

    /// @dev Runs on every transfer.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (isRestrictedTransfer) {
            require(
                hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to),
                "AccessNFT: Transfers are restricted to TRANSFER_ROLE holders"
            );
        }

        // Decrease total supply if tokens are being burned.
        for (uint256 i = 0; i < ids.length; i++) {
            if (to == address(0)) {
                nftInfo[ids[i]].supply -= amounts[i];
            }

            if (nftInfo[ids[i]].isAccess) {
                require(
                    from == address(0) || from == address(this),
                    "AccessNFT: cannot transfer an access NFT that is redeemed"
                );
            }
        }
    }

    /// @dev See EIP 2918
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = controlCenter.ownerTreasury();
        royaltyAmount = (salePrice * royaltyBps) / controlCenter.MAX_BPS();
    }

    /// @dev See EIP 1155
    function uri(uint256 _nftId) public view override returns (string memory) {
        return nftInfo[_nftId].uri;
    }

    /// @dev Alternative function to return a token's URI
    function tokenURI(uint256 _nftId) public view returns (string memory) {
        return nftInfo[_nftId].uri;
    }

    /// @dev Returns whether a token represents a 'redeemed' or 'not redeemed' state.
    function isRedeemed(uint256 _nftId) public view returns (bool) {
        return nftInfo[_nftId].isAccess;
    }

    /// @dev Returns the URI for the storefront-level metadata of the contract.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @dev ERC2771Context override
    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    /// @dev ERC2771Context override
    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
