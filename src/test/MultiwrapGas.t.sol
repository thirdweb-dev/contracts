// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Target
import "contracts/Multiwrap.sol";

// Helpers
import "contracts/TWProxy.sol";
import "contracts/Forwarder.sol";

// Test imports
import "./utils/BaseTest.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockERC721.sol";
import "./mocks/MockERC1155.sol";
import "./utils/Console.sol";

interface IMultiwrapEvents {
    /// @dev Emitted when tokens are wrapped.
    event Wrapped(address indexed wrapper, uint256 indexed tokenIdOfShares, Multiwrap.WrappedContents wrappedContents);
    
    /// @dev Emitted when tokens are unwrapped.
    event Unwrapped(address indexed wrapper, uint256 indexed tokenIdOfShares, Multiwrap.WrappedContents wrappedContents);

    /// @dev Emitted when a new Owner is set.
    event NewOwner(address prevOwner, address newOwner);

    /// @dev Emitted when royalty info is updated.
    event RoyaltyUpdated(address newRoyaltyRecipient, uint256 newRoyaltyBps);
}

contract MultiwrapGasTest is BaseTest, IMultiwrapEvents {
    // Target contract
    Multiwrap internal multiwrap;

    // Helper contracts
    MockERC20 internal mockERC20;
    MockERC721 internal mockERC721;
    MockERC1155 internal mockERC1155;

    // Initialize args
    string internal name = "Multiwrap";
    string internal symbol = "MULTI";
    string internal contractURI = "ipfs://";
    address internal royaltyRecipient = address(0x1);
    uint256 internal royaltyBps = 50;

    // Actors
    address internal deployer = address(0x1);
    address internal tokenOwner = address(0x2);
    address internal nonTokenOwner = address(0x3);
    address internal shareHolder = address(0x4);

    IMultiwrap.WrappedContents internal wrappedContents;

    //  =====   Set up  =====

    function setUp() public {
        vm.startPrank(deployer);

        Forwarder trustedForwarder = new Forwarder();

        // Deploy multiwrap (behind a proxy)
        Multiwrap multiwrapImpl = new Multiwrap();

        bytes memory multiwrapInitialize = abi.encodeWithSignature(
            "initialize(address,string,string,string,address,address,uint256)",
            deployer, name, symbol, contractURI, address(trustedForwarder), royaltyRecipient, royaltyBps
        );

        multiwrap = Multiwrap(address(
            new TWProxy(
                address(multiwrapImpl),
                multiwrapInitialize
            )
        ));

        vm.stopPrank();

        vm.startPrank(tokenOwner);

        mockERC20 = new MockERC20();
        mockERC20.mint(tokenOwner, erc20AmountToWrap);

        mockERC721 = new MockERC721();
        mockERC721.mint(erc721TokensToWrap.length);

        mockERC1155 = new MockERC1155();
        mockERC1155.mintBatch(
            tokenOwner,
            erc1155TokensToWrap,
            erc1155AmountsToWrap,
            ""
        );

        vm.stopPrank();

        wrappedContents = getDefaultWrappedContents();

        setApproval721(
            wrappedContents.erc721AssetContracts, 
            true,
            tokenOwner,
            address(multiwrap)
        );
        setApproval1155(
            wrappedContents.erc1155AssetContracts, 
            true,
            tokenOwner,
            address(multiwrap)
        );
        setApproval20(
            wrappedContents.erc20AssetContracts, 
            wrappedContents.erc20AmountsToWrap,
            tokenOwner,
            address(multiwrap)
        );
    }

    //  =====   Initial state   =====

    // function testInitialState() public {
    //     (address recipient, uint256 bps) = multiwrap.getRoyaltyInfo();
    //     assertTrue(recipient == royaltyRecipient && bps == royaltyBps);

    //     assertEq(multiwrap.contractURI(), contractURI);
    //     assertEq(multiwrap.name(), name);
    //     assertEq(multiwrap.symbol(), symbol);
    //     assertEq(multiwrap.nextTokenIdToMint(), 0);
        
    //     assertEq(multiwrap.owner(), deployer);
    //     assertTrue(multiwrap.hasRole(multiwrap.DEFAULT_ADMIN_ROLE(), deployer));
    //     assertTrue(multiwrap.hasRole(keccak256("MINTER_ROLE"), deployer));
    //     assertTrue(multiwrap.hasRole(keccak256("TRANSFER_ROLE"), deployer));
    // }

    //  =====   Functionality tests   =====

    uint256 internal erc20AmountToWrap = 500 ether;
    uint256[] internal erc721TokensToWrap = [0];
    uint256[] internal erc1155TokensToWrap = [0,1,2,3];
    uint256[] internal erc1155AmountsToWrap = [20,40,60,80];

    // function _setup_wrap() internal {
    //     vm.startPrank(tokenOwner);

    //     mockERC20 = new MockERC20();
    //     mockERC20.mint(tokenOwner, erc20AmountToWrap);

    //     mockERC721 = new MockERC721();
    //     mockERC721.mint(erc721TokensToWrap.length);

    //     mockERC1155 = new MockERC1155();
    //     mockERC1155.mintBatch(
    //         tokenOwner,
    //         erc1155TokensToWrap,
    //         erc1155AmountsToWrap,
    //         ""
    //     );

    //     vm.stopPrank();
        
    // }

    function setApproval721(
        address[] memory _assets,
        bool _toApproveForAll,
        address _caller,
        address _partyToApprove
    ) internal {
        
        vm.startPrank(_caller);
        for(uint i = 0; i < _assets.length; i += 1) {
            MockERC721(_assets[i]).setApprovalForAll(_partyToApprove, _toApproveForAll);
        }

        vm.stopPrank();
    }

    function setApproval1155(
        address[] memory _assets,
        bool _toApproveForAll,
        address _caller,
        address _partyToApprove
    ) internal {
        vm.startPrank(_caller);

        for(uint i = 0; i < _assets.length; i += 1) {
            MockERC1155(_assets[i]).setApprovalForAll(_partyToApprove, _toApproveForAll);
        }

        vm.stopPrank();
    }

    function setApproval20(
        address[] memory _assets,
        uint256[] memory _amountToApprove,
        address _caller,
        address _partyToApprove
    ) internal {
        vm.startPrank(_caller);

        for(uint i = 0; i < _assets.length; i += 1) {
            MockERC20(_assets[i]).approve(_partyToApprove, _amountToApprove[i]);
        }

        vm.stopPrank();
    }

    function getDefaultWrappedContents() internal returns (IMultiwrap.WrappedContents memory wrappedContents) {
        address[] memory erc1155AssetContracts_;
        // address[] memory erc1155AssetContracts_ = new address[](1);
        // erc1155AssetContracts_[0] = address(mockERC1155);
        uint256[][] memory erc1155TokensToWrap_;
        // uint256[][] memory erc1155TokensToWrap_ = new uint256[][](1);
        // erc1155TokensToWrap_[0] = erc1155TokensToWrap;
        uint256[][] memory erc1155AmountsToWrap_;
        // uint256[][] memory erc1155AmountsToWrap_ = new uint256[][](1);
        // erc1155AmountsToWrap_[0] = erc1155AmountsToWrap;

        address[] memory erc721AssetContracts_ = new address[](1);
        erc721AssetContracts_[0] = address(mockERC721);

        uint256[][] memory erc721TokensToWrap_ = new uint256[][](1);
        erc721TokensToWrap_[0] = erc721TokensToWrap;
        
        address[] memory erc20AssetContracts_ = new address[](1);
        erc20AssetContracts_[0] = address(mockERC20);
        
        uint256[] memory erc20AmountsToWrap_ = new uint256[](1);
        erc20AmountsToWrap_[0] = erc20AmountToWrap;

        return IMultiwrap.WrappedContents({
            erc1155AssetContracts: erc1155AssetContracts_,
            erc1155TokensToWrap: erc1155TokensToWrap_,
            erc1155AmountsToWrap: erc1155AmountsToWrap_,
            erc721AssetContracts: erc721AssetContracts_,
            erc721TokensToWrap: erc721TokensToWrap_,
            erc20AssetContracts: erc20AssetContracts_,
            erc20AmountsToWrap: erc20AmountsToWrap_
        });
    } 

    /// @dev Test `wrap`
    function test_wrap() public {
        // _setup_wrap();
        
        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";

        // uint256 tokenIdExpected = multiwrap.nextTokenIdToMint();

        // uint256 ownerBalBeforeERC20 = mockERC20.balanceOf(tokenOwner);

        vm.prank(tokenOwner);
        multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);

        // assertEq(multiwrap.tokenURI(tokenIdExpected), uriForShares);
        // assertEq(multiwrap.totalSupply(tokenIdExpected), sharesToMint);
        // assertEq(multiwrap.totalShares(tokenIdExpected), sharesToMint);
        // assertEq(multiwrap.balanceOf(tokenOwner, tokenIdExpected), sharesToMint);

        // assertEq(mockERC20.balanceOf(tokenOwner), erc20AmountToWrap - ownerBalBeforeERC20);
    }
    
}