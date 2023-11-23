// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";
import "../../utils/Wallet.sol";
import "../../mocks/WETH9.sol";
import "../../mocks/MockERC20.sol";
import "../../mocks/MockERC721.sol";
import "../../mocks/MockERC1155.sol";
import { MockERC721NonBurnable } from "../../mocks/MockERC721NonBurnable.sol";
import { MockERC1155NonBurnable } from "../../mocks/MockERC1155NonBurnable.sol";
import "contracts/infra/forwarder/Forwarder.sol";

abstract contract ExtensionUtilTest is DSTest, Test {
    string public constant NAME = "NAME";
    string public constant SYMBOL = "SYMBOL";
    string public constant CONTRACT_URI = "CONTRACT_URI";
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    MockERC20 public erc20;
    MockERC721 public erc721;
    MockERC1155 public erc1155;
    MockERC721NonBurnable public erc721NonBurnable;
    MockERC1155NonBurnable public erc1155NonBurnable;
    WETH9 public weth;

    address public forwarder;

    address public deployer = address(0x20000);
    address public saleRecipient = address(0x30000);
    address public royaltyRecipient = address(0x30001);
    address public platformFeeRecipient = address(0x30002);
    uint128 public royaltyBps = 500; // 5%
    uint128 public platformFeeBps = 500; // 5%
    uint256 public constant MAX_BPS = 10_000; // 100%

    uint256 public privateKey = 1234;
    address public signer;

    mapping(bytes32 => address) public contracts;

    function setUp() public virtual {
        signer = vm.addr(privateKey);

        erc20 = new MockERC20();
        erc721 = new MockERC721();
        erc1155 = new MockERC1155();
        erc721NonBurnable = new MockERC721NonBurnable();
        erc1155NonBurnable = new MockERC1155NonBurnable();
        weth = new WETH9();
        forwarder = address(new Forwarder());
    }

    function getActor(uint160 _index) public pure returns (address) {
        return address(uint160(0x50000 + _index));
    }

    function getWallet() public returns (Wallet wallet) {
        wallet = new Wallet();
    }

    function assertIsOwnerERC721(address _token, address _owner, uint256[] memory _tokenIds) internal {
        for (uint256 i = 0; i < _tokenIds.length; i += 1) {
            bool isOwnerOfToken = MockERC721(_token).ownerOf(_tokenIds[i]) == _owner;
            assertTrue(isOwnerOfToken);
        }
    }

    function assertIsNotOwnerERC721(address _token, address _owner, uint256[] memory _tokenIds) internal {
        for (uint256 i = 0; i < _tokenIds.length; i += 1) {
            bool isOwnerOfToken = MockERC721(_token).ownerOf(_tokenIds[i]) == _owner;
            assertTrue(!isOwnerOfToken);
        }
    }

    function assertBalERC1155Eq(
        address _token,
        address _owner,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) internal {
        require(_tokenIds.length == _amounts.length, "unequal lengths");

        for (uint256 i = 0; i < _tokenIds.length; i += 1) {
            assertEq(MockERC1155(_token).balanceOf(_owner, _tokenIds[i]), _amounts[i]);
        }
    }

    function assertBalERC1155Gte(
        address _token,
        address _owner,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) internal {
        require(_tokenIds.length == _amounts.length, "unequal lengths");

        for (uint256 i = 0; i < _tokenIds.length; i += 1) {
            assertTrue(MockERC1155(_token).balanceOf(_owner, _tokenIds[i]) >= _amounts[i]);
        }
    }

    function assertBalERC20Eq(address _token, address _owner, uint256 _amount) internal {
        assertEq(MockERC20(_token).balanceOf(_owner), _amount);
    }

    function assertBalERC20Gte(address _token, address _owner, uint256 _amount) internal {
        assertTrue(MockERC20(_token).balanceOf(_owner) >= _amount);
    }

    function forwarders() public view returns (address[] memory) {
        address[] memory _forwarders = new address[](1);
        _forwarders[0] = forwarder;
        return _forwarders;
    }
}
