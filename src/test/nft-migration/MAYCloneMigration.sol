// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/base/ERC721LazyMint.sol";
import "contracts/base/ERC1155Base.sol";
import "contracts/base/ERC721Drop.sol";

contract MAYCloneMigration is ERC721LazyMint {
    using TWStrings for uint256;
    // Store constant values for the 2 NFT Collections:
    // 1. Is the BAYC NFT Collection
    ERC721LazyMint public immutable bayc;
    // 2. Is the Serum NFT Collection
    ERC1155Base public immutable serum;

    ERC721LazyMint public immutable migrationContract;

    uint256 public immutable newStartId;

    address internal serumOwner;
    uint256 internal serumId = 0;

    uint256 internal totalMigrated;
    mapping(uint256 => string) internal migratedURI;
    mapping(uint256 => address) internal migratedTokenOwner;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _baycAddress,
        address _serumAddress,
        address _serumOwner,
        address _migrationContract,
        uint256 _newStartId
    ) ERC721LazyMint(_name, _symbol, _royaltyRecipient, _royaltyBps) {
        bayc = ERC721LazyMint(_baycAddress);
        serum = ERC1155Base(_serumAddress);
        migrationContract = ERC721LazyMint(_migrationContract);

        serumOwner = _serumOwner;

        nextTokenIdToLazyMint = _newStartId;
        _currentIndex = _newStartId;
        newStartId = _newStartId;

        serum.setApprovalForAll(address(migrationContract), true);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {}

    function migrateToken(uint256 _tokenId) external nonReentrant {
        require(_tokenId < newStartId, "Migrating invalid tokenId");
        require(migratedTokenOwner[_tokenId] == address(0), "Already migrated");
        require(migrationContract.ownerOf(_tokenId) == msg.sender, "Not owner");

        uint256 curr = _currentIndex;
        _currentIndex = _tokenId;
        _mint(msg.sender, 1);
        _currentIndex = curr;

        totalMigrated += 1;
        migratedTokenOwner[_tokenId] = msg.sender;
        migratedURI[_tokenId] = migrationContract.tokenURI(_tokenId);

        // serum.mintTo(msg.sender, 0, "", 1); -- only owner can do this
        serum.safeTransferFrom(serumOwner, address(this), serumId, 1, "");
        migrationContract.burn(_tokenId);
    }

    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return totalMigrated + _currentIndex - _burnCounter - newStartId;
        }
    }

    function ownerOf(uint256 _tokenId) public view override returns (address) {
        require(migratedTokenOwner[_tokenId] != address(0) || _tokenId >= newStartId, "Invalid tokenId");
        return _ownershipOf(_tokenId).addr;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (_tokenId < newStartId) {
            require(bytes(migratedURI[_tokenId]).length != 0, "Invalid tokenId");
            return migratedURI[_tokenId];
        }
        string memory batchUri = _getBaseURI(_tokenId);
        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    function getApproved(uint256 _tokenId) public view override returns (address) {
        if (_tokenId < newStartId) {
            require(migratedTokenOwner[_tokenId] != address(0), "Invalid tokenId");
        }

        return super.getApproved(_tokenId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (startTokenId < newStartId) {
            require(migratedTokenOwner[startTokenId] != address(0) || from == address(0), "Invalid tokenId");
        }
    }

    function verifyClaim(address _claimer, uint256 _quantity) public view virtual override {
        // 1. Override the claim function to ensure a few things:
        // - They own an NFT from the BAYClone contract
        require(bayc.balanceOf(_claimer) >= _quantity, "You don't own enough BAYC NFTs");
        // - They own an NFT from the SerumClone contract
        require(serum.balanceOf(_claimer, 0) >= _quantity, "You don't own enough Serum NFTs");
    }

    function _transferTokensOnClaim(address _receiver, uint256 _quantity) internal override returns (uint256) {
        serum.burn(_receiver, 0, _quantity);

        // Use the rest of the inherited claim function logic
        return super._transferTokensOnClaim(_receiver, _quantity);
    }

    function _startTokenId() internal view override returns (uint256) {
        return 0;
    }
}
