// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC721.sol";

import "../../feature/ContractMetadata.sol";
import "../../feature/Multicall.sol";
import "../../feature/Ownable.sol";
import "../../feature/Royalty.sol";
import "../../feature/SignatureMintERC721.sol";

contract ERC721Base is 
    ERC721,
    ContractMetadata,
    Multicall,
    Ownable,
    Royalty,
    SignatureMintERC721
{
    uint256 public nextTokenIdToMint;
    string public baseURI;

    mapping(uint256 => string) private _tokenURIs;

    constructor(
        string memory _name, 
        string memory _symbol,
        string memory _contractURI,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC721(_name, _symbol) 
    {
        _setupContractURI(_contractURI);
        _setupOwner(msg.sender);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }

    function tokenURI(uint256 _tokenId) public virtual view returns (string memory) {
        require(ownerOf(_tokenId) != address(0), "Invalid Id");

        string memory _tokenURI = _tokenURIs[_tokenId];
        string memory base = baseURI;

        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return base;
    }

    function mint(address _to, string memory _tokenURI, bytes memory _data) external virtual onlyOwner {
        uint256 _id = nextTokenIdToMint;
        nextTokenIdToMint += 1;

        _safeMint(_to, _id, _data);
        _setTokenURI(_id, _tokenURI);
    }

    function mintWithSignature(MintRequest calldata _req, bytes calldata _signature)
        external
        payable
        returns (address signer) 
    {
        require(_req.quantity == 1, "can mint exactly one");

        uint256 tokenIdToMint = nextTokenIdToMint;
        // require(tokenIdToMint + _req.quantity <= nextTokenIdToMint, "not enough minted tokens.");
        
        nextTokenIdToMint += 1;

        // Verify and process payload.
        signer = _processRequest(_req, _signature);

        /**
         *  Get receiver of tokens.
         *
         *  Note: If `_req.to == address(0)`, a `mintWithSignature` transaction sitting in the
         *        mempool can be frontrun by copying the input data, since the minted tokens
         *        will be sent to the `_msgSender()` in this case.
         */
        address receiver = _req.to == address(0) ? msg.sender : _req.to;

        // Collect price
        // collectPriceOnClaim(_req.quantity, _req.currency, _req.pricePerToken);

        // Mint tokens.
        _safeMint(receiver, tokenIdToMint, "");

        _setTokenURI(tokenIdToMint, _req.uri);

        emit TokensMintedWithSignature(signer, receiver, tokenIdToMint, _req);
    }

    function setBaseURI(string memory _baseURI) external virtual onlyOwner {
        // require(bytes(baseURI).length == 0, "Base URI already set");
        baseURI = _baseURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(ownerOf(tokenId) != address(0), "Invalid Id");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /// @dev Returns whether a given address is authorized to sign mint requests.
    function _isAuthorizedSigner(address _signer) internal view virtual override returns (bool) {
        return _signer == owner();
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal virtual view override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal virtual override view returns (bool) {
        return msg.sender == owner();
    }
}
