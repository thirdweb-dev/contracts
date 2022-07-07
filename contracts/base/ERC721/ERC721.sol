// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract ERC721 {

    /*//////////////////////////////////////////////////////////////
                        State variables
    //////////////////////////////////////////////////////////////*/

    /// @notice The display name of the ERC721 collection.
    string public name;

    /// @notice The display symbol of the ERC721 collection.
    string public symbol;

    /*//////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when `from` transfers an NFT of tokenId `id` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    
    /// @dev Emitted when `owner` approves `spender` to transfer an NFT of tokenId `id`.
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    /// @dev Emitted when `owner` approves or revokes approval from `operator` to transfer any NFTs owned by `owner`.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                            Mappings
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping from NFT tokenId => address approved to transfer the NFT of that tokenId.
    mapping(uint256 => address) public getApproved;

    /// @notice Mapping from owner address => operator address => whether owner has approved operator to transfer any owned NFTs.
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @notice Mapping from NFT tokenId => address of the owner of that NFT.
    mapping(uint256 => address) internal _ownerOf;

    /// @notice Mapping from address => number of NFTs of this contract owned by the address.
    mapping(address => uint256) internal _balanceOf;

    /// @notice Mapping from NFT tokenId => metadata URI for the NFT of that tokenId.
    mapping(uint256 => string) internal _tokenURI;

    /*//////////////////////////////////////////////////////////////
                            ERC165 Logic
    //////////////////////////////////////////////////////////////*/

    /// @dev See ERC165: https://eips.ethereum.org/EIPS/eip-165
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 Logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice       Returns the address of the owner an NFT on this contract.
     *  @dev          Contract execution reverts if the NFT of tokenId `id` has no owner i.e. owner is the zero address.
     *
     *  @param id     The tokenId of an NFT.
     *  @return owner The owner of the NFT of tokenID `id`.
     */
    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    /**
     *  @notice      Returns the number of NFTs on this contract owned by an address.
     *  @dev         Contract execution reverts when querying the balance of the zero address.
     *
     *  @param owner The address whose NFT balance is to be queried.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /**
     *  @notice   Returns the metadata URI for an NFT.
     *
     *  @param id The tokenId of an NFT.
     */
    function tokenURI(uint256 id) public view virtual returns (string memory) {
        return _tokenURI[id];
    }

    /**
     *  @notice        Lets the owner of an NFT approve a spender to transfer that NFT on the owner's behalf.
     *  @dev           The caller can either be the owner of the concerned NFT, or an address 'approved for all' by the owner.
     *
     *  @param spender The address to approve to transfer the NFT.
     *  @param id      The tokenId of the NFT.
     */
    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    /**
     *  @notice         Lets an address approve an operator to transfer or grant transfer approvals for any of their NFTs.
     *
     *  @param operator The address to approve.
     *  @param approved Whether to grant approval or revoke approval from the operator.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     *  @notice     Transfer an NFT from its owner to a recipient.
     *  @dev        The caller must either be the owner of the NFT, or be approved to transfer the NFT.
     *
     *  @param from The owner of the NFT to transfer.
     *  @param to   The recipient of the NFT being transferred.
     *  @param id   The tokenId of the NFT to transfer.
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    /**
     *  @notice     Transfer an NFT from its owner to a recipient. If the recipient is a smart contract, it must be eligible to recieve NFTs.
     *  @dev        The caller must either be the owner of the NFT, or be approved to transfer the NFT. If the recipient is a smart contract,
     *              it must implement the ERC721Receiver interface.
     *
     *  @param from The owner of the NFT to transfer.
     *  @param to   The recipient of the NFT being transferred.
     *  @param id   The tokenId of the NFT to transfer.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /**
     *  @notice     Transfer an NFT from its owner to a recipient. If the recipient is a smart contract, it must be eligible to recieve NFTs.
     *  @dev        The caller must either be the owner of the NFT, or be approved to transfer the NFT. If the recipient is a smart contract,
     *              it must implement the ERC721Receiver interface.
     *
     *  @param from The owner of the NFT to transfer.
     *  @param to   The recipient of the NFT being transferred.
     *  @param id   The tokenId of the NFT to transfer.
     *  @param data Additional data to pass along to a smart contract recipient of the NFT.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice   Mints an NFT to a recipient.
     *  @dev      The NFT must not already exist, and the recipient must not be the zero address.
     *
     *  @param to The recipient of the NFT to mint.
     *  @param id The tokenId of the NFT to mint.
     */
    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    /**
     *  @notice   Burns an NFT i.e. takes it out of existence.
     *  @dev      The NFT must already exist in order to be burned.
     *
     *  @param id The tokenId of the NFT to burn.
     */
    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /**
     *  @notice Returns whether an NFT of the given `tokenId` has been minted and not burned.
     *
     *  @param tokenId The tokenId of an NFT.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    /**
     *  @notice   Mints an NFT to a recipient. If the recipient is a smart contract, it must be eligible to recieve NFTs.
     *  @dev      The NFT must not already exist, and the recipient must not be the zero address. If the recipient is a smart contract,
     *            it must implement the ERC721Receiver interface.
     *
     *  @param to The recipient of the NFT to mint.
     *  @param id The tokenId of the NFT to mint.
     */
    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /**
     *  @notice     Mints an NFT to a recipient. If the recipient is a smart contract, it must be eligible to recieve NFTs.
     *  @dev        The NFT must not already exist, and the recipient must not be the zero address. If the recipient is a smart contract,
     *              it must implement the ERC721Receiver interface.
     *
     *  @param to   The recipient of the NFT to mint.
     *  @param id   The tokenId of the NFT to mint.
     *  @param data Additional data to pass along to a smart contract recipient of the NFT.
     */
    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}