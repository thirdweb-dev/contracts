// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/stdlib.sol";
import "@ds-test/test.sol";
import "./Console.sol";
import "./Wallet.sol";
import "../mocks/WETH9.sol";
import "../mocks/MockERC20.sol";
import "../mocks/MockERC721.sol";
import "../mocks/MockERC1155.sol";
import "contracts/Forwarder.sol";
import "contracts/TWFee.sol";
import "contracts/TWRegistry.sol";
import "contracts/TWFactory.sol";
import "contracts/Multiwrap.sol";
import "contracts/Pack.sol";
import "contracts/Split.sol";
import "contracts/drop/DropERC20.sol";
import "contracts/drop/DropERC721.sol";
import "contracts/drop/DropERC1155.sol";
import "contracts/token/TokenERC20.sol";
import "contracts/token/TokenERC721.sol";
import "contracts/token/TokenERC1155.sol";
import "contracts/marketplace/Marketplace.sol";
import "contracts/vote/VoteERC20.sol";

abstract contract BaseTest is DSTest, stdCheats {
    string public constant NAME = "NAME";
    string public constant SYMBOL = "SYMBOL";
    string public constant CONTRACT_URI = "CONTRACT_URI";
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // solhint-disable-next-line
    Vm public constant vm = Vm(HEVM_ADDRESS);

    MockERC20 public erc20;
    MockERC721 public erc721;
    MockERC1155 public erc1155;

    address public forwarder;
    address public registry;
    address public factory;
    address public fee;
    address public weth;

    address public factoryAdmin = address(0x10000);
    address public deployer = address(0x20000);
    address public saleRecipient = address(0x30000);
    address public royaltyRecipient = address(0x30001);
    address public platformFeeRecipient = address(0x30002);
    uint128 public royaltyBps = 500; // 5%
    uint128 public platformFeeBps = 500; // 5%

    mapping(bytes32 => address) public contracts;

    function setUp() public virtual {
        /// setup main factory contracts. registry, fee, factory.
        vm.startPrank(factoryAdmin);
        erc20 = new MockERC20();
        erc721 = new MockERC721();
        erc1155 = new MockERC1155();
        weth = address(new WETH9());
        forwarder = address(new Forwarder());
        registry = address(new TWRegistry(forwarder));
        factory = address(new TWFactory(forwarder, registry));
        TWRegistry(registry).grantRole(TWRegistry(registry).OPERATOR_ROLE(), factory);
        fee = address(new TWFee(forwarder, factory));
        TWFactory(factory).addImplementation(address(new TokenERC20(fee)));
        TWFactory(factory).addImplementation(address(new TokenERC721(fee)));
        TWFactory(factory).addImplementation(address(new TokenERC1155(fee)));
        TWFactory(factory).addImplementation(address(new DropERC20(fee)));
        TWFactory(factory).addImplementation(address(new DropERC721(fee)));
        TWFactory(factory).addImplementation(address(new DropERC1155(fee)));
        TWFactory(factory).addImplementation(address(new Marketplace(weth, fee)));
        TWFactory(factory).addImplementation(address(new Split(fee)));
        // TWFactory(factory).addImplementation(address(new Pack(address(0), address(0), fee)));
        TWFactory(factory).addImplementation(address(new Multiwrap()));
        TWFactory(factory).addImplementation(address(new VoteERC20()));
        vm.stopPrank();

        /// deploy proxy for tests
        deployContractProxy(
            "TokenERC20",
            abi.encodeCall(
                TokenERC20.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    platformFeeRecipient,
                    platformFeeBps
                )
            )
        );
        deployContractProxy(
            "TokenERC721",
            abi.encodeCall(
                TokenERC721.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    royaltyRecipient,
                    royaltyBps,
                    platformFeeBps,
                    platformFeeRecipient
                )
            )
        );
        deployContractProxy(
            "TokenERC1155",
            abi.encodeCall(
                TokenERC1155.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    royaltyRecipient,
                    royaltyBps,
                    platformFeeBps,
                    platformFeeRecipient
                )
            )
        );
        deployContractProxy(
            "DropERC20",
            abi.encodeCall(
                DropERC20.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    platformFeeBps,
                    platformFeeRecipient
                )
            )
        );
        deployContractProxy(
            "DropERC721",
            abi.encodeCall(
                DropERC721.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    royaltyRecipient,
                    royaltyBps,
                    platformFeeBps,
                    platformFeeRecipient
                )
            )
        );
        deployContractProxy(
            "DropERC1155",
            abi.encodeCall(
                DropERC1155.initialize,
                (
                    deployer,
                    NAME,
                    SYMBOL,
                    CONTRACT_URI,
                    forwarders(),
                    saleRecipient,
                    royaltyRecipient,
                    royaltyBps,
                    platformFeeBps,
                    platformFeeRecipient
                )
            )
        );
        deployContractProxy(
            "Marketplace",
            abi.encodeCall(
                Marketplace.initialize,
                (deployer, CONTRACT_URI, forwarders(), platformFeeRecipient, platformFeeBps)
            )
        );
        deployContractProxy(
            "Multiwrap",
            abi.encodeCall(
                Multiwrap.initialize,
                (deployer, NAME, SYMBOL, CONTRACT_URI, forwarders(), royaltyRecipient, royaltyBps)
            )
        );
    }

    function deployContractProxy(string memory _contractType, bytes memory _initializer)
        public
        returns (address proxyAddress)
    {
        vm.startPrank(deployer);
        proxyAddress = TWFactory(factory).deployProxy(bytes32(bytes(_contractType)), _initializer);
        contracts[bytes32(bytes(_contractType))] = proxyAddress;
        vm.stopPrank();
    }

    function getContract(string memory _name) public view returns (address) {
        return contracts[bytes32(bytes(_name))];
    }

    function getActor(uint160 _index) public pure returns (address) {
        return address(uint160(0x50000 + _index));
    }

    function getWallet() public returns (Wallet wallet) {
        wallet = new Wallet();
    }

    function assertIsOwnerERC721(
        address _token,
        address _owner,
        uint256[] memory _tokenIds
    ) internal {
        for (uint256 i = 0; i < _tokenIds.length; i += 1) {
            bool isOwnerOfToken = MockERC721(_token).ownerOf(_tokenIds[i]) == _owner;
            assertTrue(isOwnerOfToken);
        }
    }

    function assertIsNotOwnerERC721(
        address _token,
        address _owner,
        uint256[] memory _tokenIds
    ) internal {
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

    function assertBalERC20Eq(
        address _token,
        address _owner,
        uint256 _amount
    ) internal {
        assertEq(MockERC20(_token).balanceOf(_owner), _amount);
    }

    function assertBalERC20Gte(
        address _token,
        address _owner,
        uint256 _amount
    ) internal {
        assertTrue(MockERC20(_token).balanceOf(_owner) >= _amount);
    }

    function forwarders() public view returns (address[] memory) {
        address[] memory _forwarders = new address[](1);
        _forwarders[0] = forwarder;
        return _forwarders;
    }
}
