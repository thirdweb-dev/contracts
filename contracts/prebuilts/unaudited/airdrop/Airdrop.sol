// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

import { Initializable } from "../../../extension/Initializable.sol";
import { Ownable } from "../../../extension/Ownable.sol";

import "../../../eip/interface/IERC721.sol";
import "../../../eip/interface/IERC1155.sol";
import "../../../lib/MerkleProof.sol";
import "../../../lib/CurrencyTransferLib.sol";

contract Airdrop is Initializable, Ownable {
    /*///////////////////////////////////////////////////////////////
                            State & structs
    //////////////////////////////////////////////////////////////*/

    // ERC20 claimable
    address public tokenAddress20;
    mapping(address => bytes32) public merkleRoot20;
    mapping(address => bool) public claimed20;

    // Native token claimable
    bytes32 public merkleRootETH;
    mapping(address => bool) public claimedETH;

    // ERC721 claimable
    address public tokenAddress721;
    mapping(address => bytes32) public merkleRoot721;
    mapping(uint256 => bool) public claimed721;

    // ERC1155 claimable
    address public tokenAddress1155;
    mapping(address => bytes32) public merkleRoot1155;
    mapping(uint256 => mapping(address => bool)) public claimed1155;

    struct AirdropContent20 {
        address recipient;
        uint256 amount;
    }

    struct AirdropContent721 {
        address recipient;
        uint256 tokenId;
    }

    struct AirdropContent1155 {
        address recipient;
        uint256 tokenId;
        uint256 amount;
    }

    /*///////////////////////////////////////////////////////////////
                                Errors
    //////////////////////////////////////////////////////////////*/

    error AirdropInvalidProof();
    error AirdropFailed();
    error AirdropNoMerkleRoot();
    error AirdropValueMismatch();

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    function initialize(address _defaultAdmin) external initializer {
        _setupOwner(_defaultAdmin);
    }

    /*///////////////////////////////////////////////////////////////
                            Airdrop Push
    //////////////////////////////////////////////////////////////*/

    function airdropERC20(address _tokenAddress, AirdropContent20[] calldata _contents) external {
        address _from = msg.sender;
        uint256 len = _contents.length;

        for (uint256 i = 0; i < len; ) {
            CurrencyTransferLib.transferCurrency(_tokenAddress, _from, _contents[i].recipient, _contents[i].amount);

            unchecked {
                i += 1;
            }
        }
    }

    function airdropNativeToken(AirdropContent20[] calldata _contents) external payable {
        uint256 len = _contents.length;

        uint256 nativeTokenAmount;
        uint256 refundAmount;

        for (uint256 i = 0; i < len; ) {
            nativeTokenAmount += _contents[i].amount;

            if (nativeTokenAmount > msg.value) {
                revert AirdropValueMismatch();
            }

            (bool success, ) = _contents[i].recipient.call{ value: _contents[i].amount }("");

            if (!success) {
                refundAmount += _contents[i].amount;
            }

            unchecked {
                i += 1;
            }
        }

        if (nativeTokenAmount != msg.value) {
            revert AirdropValueMismatch();
        }

        if (refundAmount > 0) {
            // refund failed payments' amount to sender address
            // solhint-disable avoid-low-level-calls
            // slither-disable-next-line low-level-calls
            (bool refundSuccess, ) = msg.sender.call{ value: refundAmount }("");
        }
    }

    function airdrop721(address _tokenAddress, AirdropContent721[] calldata _contents) external {
        address _from = msg.sender;

        uint256 len = _contents.length;

        for (uint256 i = 0; i < len; ) {
            IERC721(_tokenAddress).safeTransferFrom(_from, _contents[i].recipient, _contents[i].tokenId);

            unchecked {
                i += 1;
            }
        }
    }

    function airdropERC1155(address _tokenAddress, AirdropContent1155[] calldata _contents) external {
        address _from = msg.sender;

        uint256 len = _contents.length;

        for (uint256 i = 0; i < len; ) {
            IERC1155(_tokenAddress).safeTransferFrom(
                _from,
                _contents[i].recipient,
                _contents[i].tokenId,
                _contents[i].amount,
                ""
            );

            unchecked {
                i += 1;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Airdrop Claimable
    //////////////////////////////////////////////////////////////*/

    function claim20(address _token, address _receiver, uint256 _quantity, bytes32[] calldata _proofs) external {
        bytes32 _merkleRoot = merkleRoot20[_token];

        if (_merkleRoot == bytes32(0)) {
            revert AirdropNoMerkleRoot();
        }

        bool valid;
        (valid, ) = MerkleProof.verify(_proofs, _merkleRoot, keccak256(abi.encodePacked(msg.sender, _quantity)));

        if (!valid) {
            revert AirdropInvalidProof();
        }

        claimed20[msg.sender] = true;

        CurrencyTransferLib.transferCurrency(tokenAddress20, owner(), _receiver, _quantity);
    }

    function claimETH(address _receiver, uint256 _quantity, bytes32[] calldata _proofs) external {
        bool valid;
        (valid, ) = MerkleProof.verify(_proofs, merkleRootETH, keccak256(abi.encodePacked(msg.sender, _quantity)));

        if (!valid) {
            revert AirdropInvalidProof();
        }

        claimedETH[msg.sender] = true;

        (bool success, ) = _receiver.call{ value: _quantity }("");
        if (!success) revert AirdropFailed();
    }

    function claim721(address _token, address _receiver, uint256 _tokenId, bytes32[] calldata _proofs) external {
        bytes32 _merkleRoot = merkleRoot721[_token];

        if (_merkleRoot == bytes32(0)) {
            revert AirdropNoMerkleRoot();
        }

        bool valid;
        (valid, ) = MerkleProof.verify(_proofs, _merkleRoot, keccak256(abi.encodePacked(msg.sender, _tokenId)));

        if (!valid) {
            revert AirdropInvalidProof();
        }

        claimed721[_tokenId] = true;

        IERC721(tokenAddress721).safeTransferFrom(owner(), _receiver, _tokenId);
    }

    function claim1155(
        address _token,
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity,
        bytes32[] calldata _proofs
    ) external {
        bytes32 _merkleRoot = merkleRoot1155[_token];

        if (_merkleRoot == bytes32(0)) {
            revert AirdropNoMerkleRoot();
        }

        bool valid;
        (valid, ) = MerkleProof.verify(_proofs, _merkleRoot, keccak256(abi.encodePacked(msg.sender, _quantity)));

        if (!valid) {
            revert AirdropInvalidProof();
        }

        claimed1155[_tokenId][msg.sender] = true;

        IERC1155(tokenAddress1155).safeTransferFrom(owner(), _receiver, _tokenId, _quantity, "");
    }

    /*///////////////////////////////////////////////////////////////
                            Setter functions
    //////////////////////////////////////////////////////////////*/

    function setMerkleRoot20(address _token, bytes32 _merkleRoot) external onlyOwner {
        merkleRoot20[_token] = _merkleRoot;
    }

    function setMerkleRootETH(bytes32 _merkleRoot) external onlyOwner {
        merkleRootETH = _merkleRoot;
    }

    function setMerkleRoot721(address _token, bytes32 _merkleRoot) external onlyOwner {
        merkleRoot721[_token] = _merkleRoot;
    }

    function setMerkleRoot1155(address _token, bytes32 _merkleRoot) external onlyOwner {
        merkleRoot1155[_token] = _merkleRoot;
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}
