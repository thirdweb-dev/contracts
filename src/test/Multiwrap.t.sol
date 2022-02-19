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
    event TokensWrapped(address indexed wrapper, uint256 indexed tokenIdOfShares, Multiwrap.WrappedContents wrappedContents);
    
    /// @dev Emitted when tokens are unwrapped.
    event TokensUnwrapped(address indexed wrapper, uint256 indexed tokenIdOfShares, uint256 sharesUnwrapped, Multiwrap.WrappedContents wrappedContents);
}

contract MockERC20Reentrancy is MockERC20 {

    uint256 targetTokenId;
    Multiwrap multiwrap;

    bool toReenter;

    constructor(address _multiwrap) MockERC20() {
        multiwrap = Multiwrap(_multiwrap);
    }

    function setToReenter(bool _toReenter) external {
        toReenter = _toReenter;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {

        if(_msgSender() == address(multiwrap) && toReenter) {
            multiwrap.unwrap(targetTokenId);
        } else {
            _transfer(sender, recipient, amount);

            uint256 currentAllowance = allowance(sender,_msgSender());
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if(_msgSender() == address(multiwrap)) {
            multiwrap.unwrap(targetTokenId);
        } else {
            _transfer(_msgSender(), recipient, amount);
        }
        
        return true;
    }
}

contract MultiwrapTest is BaseTest, IMultiwrapEvents {
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
    }

    //  =====   Initial state   =====

    function testInitialState() public {
        (address recipient, uint256 bps) = multiwrap.getRoyaltyInfo();
        assertTrue(recipient == royaltyRecipient && bps == royaltyBps);

        assertEq(multiwrap.contractURI(), contractURI);
        assertEq(multiwrap.name(), name);
        assertEq(multiwrap.symbol(), symbol);
        assertEq(multiwrap.nextTokenIdToMint(), 0);
        
        assertEq(multiwrap.owner(), deployer);
        assertTrue(multiwrap.hasRole(multiwrap.DEFAULT_ADMIN_ROLE(), deployer));
        assertTrue(multiwrap.hasRole(keccak256("MINTER_ROLE"), deployer));
        assertTrue(multiwrap.hasRole(keccak256("TRANSFER_ROLE"), deployer));
    }

    //  =====   Functionality tests   =====

    uint256 internal erc20AmountToWrap = 500 ether;
    uint256[] internal erc721TokensToWrap = [0,1,2];
    uint256[] internal erc1155TokensToWrap = [0,1,2,3];
    uint256[] internal erc1155AmountsToWrap = [20,40,60,80];

    IMultiwrap.WrappedContents wrappedContents;

    function _setup_wrap() internal {
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
            true,
            tokenOwner,
            address(multiwrap)
        );
    }

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
        bool _toApprove,
        address _caller,
        address _partyToApprove
    ) internal {
        vm.prank(_caller);

        for(uint i = 0; i < _assets.length; i += 1) {
            if(_toApprove) {
                MockERC20(_assets[i]).increaseAllowance(_partyToApprove, _amountToApprove[i]);
            } else {
                MockERC20(_assets[i]).decreaseAllowance(_partyToApprove, _amountToApprove[i]);
            }
        }
    }

    function getDefaultWrappedContents() internal returns (IMultiwrap.WrappedContents memory wrappedContents) {
        address[] memory erc1155AssetContracts_ = new address[](1);
        erc1155AssetContracts_[0] = address(mockERC1155);

        uint256[][] memory erc1155TokensToWrap_ = new uint256[][](1);
        erc1155TokensToWrap_[0] = erc1155TokensToWrap;

        uint256[][] memory erc1155AmountsToWrap_ = new uint256[][](1);
        erc1155AmountsToWrap_[0] = erc1155AmountsToWrap;

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
        _setup_wrap();
        
        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";

        uint256 tokenIdExpected = multiwrap.nextTokenIdToMint();
        uint256 ownerBalBeforeERC20 = mockERC20.balanceOf(tokenOwner);

        vm.prank(tokenOwner);
        multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);

        assertEq(multiwrap.tokenURI(tokenIdExpected), uriForShares);
        assertEq(multiwrap.totalSupply(tokenIdExpected), sharesToMint);
        assertEq(multiwrap.totalShares(tokenIdExpected), sharesToMint);
        assertEq(multiwrap.balanceOf(tokenOwner, tokenIdExpected), sharesToMint);

        assertEq(mockERC20.balanceOf(tokenOwner), erc20AmountToWrap - ownerBalBeforeERC20);
        for(uint i = 0; i < wrappedContents.erc721AssetContracts.length; i += 1) {
            address asset = wrappedContents.erc721AssetContracts[i];
            for(uint j = 0; j < wrappedContents.erc721TokensToWrap.length; j += 1) {
                uint256 tokenId = wrappedContents.erc721TokensToWrap[i][j];
                assertEq(
                    MockERC721(asset).ownerOf(tokenId),
                    address(multiwrap)
                );
            }
        }

        for(uint i = 0; i < wrappedContents.erc1155AssetContracts.length; i += 1) {
            address asset = wrappedContents.erc1155AssetContracts[i];
            for(uint j = 0; j < erc1155TokensToWrap.length; j += 1) {
                uint256 tokenId = wrappedContents.erc1155TokensToWrap[i][j];
                uint256 wrappedAmount = wrappedContents.erc1155AmountsToWrap[i][j];
                assertEq(
                    MockERC1155(asset).balanceOf(address(multiwrap), tokenId),
                    wrappedAmount
                );
            }
        }
    }

    function test_wrap_revert_insufficientBalance1155() public {
        _setup_wrap();
        
        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";

        vm.prank(tokenOwner);
        mockERC1155.burn(
            tokenOwner,
            0,
            1
        );

        vm.expectRevert("ERC1155: insufficient balance for transfer");

        vm.prank(tokenOwner);
        multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);
    }

    function test_wrap_revert_insufficientBalance721() public {
        _setup_wrap();
        
        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";

        vm.prank(tokenOwner);
        mockERC721.safeTransferFrom(tokenOwner, deployer, 0);

        vm.expectRevert("ERC721: transfer caller is not owner nor approved");

        vm.prank(tokenOwner);
        multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);
    }

    function test_wrap_revert_insufficientBalance20() public {
        _setup_wrap();
        
        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";

        vm.prank(tokenOwner);
        mockERC20.burn(erc20AmountToWrap);

        vm.expectRevert("ERC20: transfer amount exceeds balance");

        vm.prank(tokenOwner);
        multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);
    }

    function test_wrap_revert_unapprovedTransfer1155() public {
        _setup_wrap();
        
        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";

        setApproval1155(
            wrappedContents.erc1155AssetContracts, 
            false,
            tokenOwner,
            address(multiwrap)
        );

        vm.expectRevert("ERC1155: caller is not owner nor approved");

        vm.prank(tokenOwner);
        multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);
    }

    function test_wrap_revert_unapprovedTransfer721() public {
        _setup_wrap();
        
        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";

        setApproval721(
            wrappedContents.erc721AssetContracts, 
            false,
            tokenOwner,
            address(multiwrap)
        );

        vm.expectRevert("ERC721: transfer caller is not owner nor approved");

        vm.prank(tokenOwner);
        multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);
    }

    function test_wrap_revert_unapprovedTransfer20() public {
        _setup_wrap();
        
        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";

        setApproval20(
            wrappedContents.erc20AssetContracts, 
            wrappedContents.erc20AmountsToWrap,
            false,
            tokenOwner,
            address(multiwrap)
        );

        vm.expectRevert("ERC20: insufficient allowance");

        vm.prank(tokenOwner);
        multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);
    }

    function test_wrap_emit_Wrapped() public {
        _setup_wrap();
        
        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";
        uint256 tokenIdExpected = multiwrap.nextTokenIdToMint();

        vm.expectEmit(true, true, false, true);
        emit TokensWrapped(tokenOwner, tokenIdExpected, wrappedContents);

        vm.prank(tokenOwner);
        multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);
    }

    /// @dev Test `unwrap`

    function _setup_unwrap() internal returns (uint256 tokenIdOfWrapped) {
        _setup_wrap();
        
        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";

        tokenIdOfWrapped = multiwrap.nextTokenIdToMint();

        vm.prank(tokenOwner);
        multiwrap.wrap(wrappedContents, sharesToMint, uriForShares);
    }

    function test_unwrap() public {
        
        uint256 tokenIdOfWrapped = _setup_unwrap();
        uint256 ownerBalBeforeERC20 = mockERC20.balanceOf(tokenOwner);

        vm.prank(tokenOwner);
        multiwrap.unwrap(tokenIdOfWrapped);

        assertEq(multiwrap.totalSupply(tokenIdOfWrapped), 0);
        assertEq(multiwrap.balanceOf(tokenOwner, tokenIdOfWrapped), 0);

        assertEq(mockERC20.balanceOf(tokenOwner), erc20AmountToWrap + ownerBalBeforeERC20);
        for(uint i = 0; i < wrappedContents.erc721AssetContracts.length; i += 1) {
            address asset = wrappedContents.erc721AssetContracts[i];
            for(uint j = 0; j < wrappedContents.erc721TokensToWrap.length; j += 1) {
                uint256 tokenId = wrappedContents.erc721TokensToWrap[i][j];
                assertEq(
                    MockERC721(asset).ownerOf(tokenId),
                    tokenOwner
                );
            }
        }

        for(uint i = 0; i < wrappedContents.erc1155AssetContracts.length; i += 1) {
            address asset = wrappedContents.erc1155AssetContracts[i];
            for(uint j = 0; j < erc1155TokensToWrap.length; j += 1) {
                uint256 tokenId = wrappedContents.erc1155TokensToWrap[i][j];
                uint256 wrappedAmount = wrappedContents.erc1155AmountsToWrap[i][j];
                assertEq(
                    MockERC1155(asset).balanceOf(address(multiwrap), tokenId),
                    0
                );
                assertEq(
                    MockERC1155(asset).balanceOf(tokenOwner, tokenId),
                    wrappedAmount
                );
            }
        }
    }

    function test_unwrap_revert_invalidTokenId() public {
        _setup_unwrap();

        uint256 invalidId = multiwrap.nextTokenIdToMint();

        vm.expectRevert("invalid tokenId");

        vm.prank(tokenOwner);
        multiwrap.unwrap(invalidId);
    }

    function test_unwrap_revert_insufficientShares() public {
        uint256 tokenIdOfWrapped = _setup_unwrap();

        vm.prank(tokenOwner);
        multiwrap.safeTransferFrom(tokenOwner, deployer, tokenIdOfWrapped, 1, "");

        vm.expectRevert("must own all shares to unwrap");

        vm.prank(tokenOwner);
        multiwrap.unwrap(tokenIdOfWrapped);
    }

    function test_unwrap_emit_Unwrapped() public {
        uint256 tokenIdOfWrapped = _setup_unwrap();
        uint256 totalShares = multiwrap.totalShares(tokenIdOfWrapped);

        vm.expectEmit(true, true, false, true);
        emit TokensUnwrapped(tokenOwner, tokenIdOfWrapped, totalShares, wrappedContents);

        vm.prank(tokenOwner);
        multiwrap.unwrap(tokenIdOfWrapped);
    }

    /// @dev Test `unwrapByShares`

    function _get_onlyWrapERC20() internal returns (IMultiwrap.WrappedContents memory onlyERC20Wrapped)  {

        onlyERC20Wrapped = getDefaultWrappedContents();

        address[] memory erc1155AssetContracts_;
        uint256[][] memory erc1155TokensToWrap_;
        uint256[][] memory erc1155AmountsToWrap_;

        address[] memory erc721AssetContracts_;
        uint256[][] memory erc721TokensToWrap_;

        onlyERC20Wrapped.erc1155AssetContracts = erc1155AssetContracts_;
        onlyERC20Wrapped.erc1155TokensToWrap = erc1155TokensToWrap_;
        onlyERC20Wrapped.erc1155AmountsToWrap = erc1155AmountsToWrap_;
        onlyERC20Wrapped.erc721AssetContracts = erc721AssetContracts_;
        onlyERC20Wrapped.erc721TokensToWrap = erc721TokensToWrap_;
    }

    function _setup_unwrapByShares() internal returns (uint256 tokenIdOfWrapped) {
        _setup_wrap();

        IMultiwrap.WrappedContents memory onlyERC20Wrapped = _get_onlyWrapERC20();
        
        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";

        tokenIdOfWrapped = multiwrap.nextTokenIdToMint();

        vm.prank(tokenOwner);
        multiwrap.wrap(onlyERC20Wrapped, sharesToMint, uriForShares);
    }

    function test_unwrapByShares() public {
        uint256 tokenIdOfWrapped =_setup_unwrapByShares();

        uint256 totalShares = multiwrap.totalShares(tokenIdOfWrapped);
        uint256 sharesToRedeem = (totalShares * 10) / 100; // 10%

        uint256 expectedRedeemAmount = (erc20AmountToWrap * sharesToRedeem) / totalShares;
        uint256 ownerBalBefore = mockERC20.balanceOf(tokenOwner);
        uint256 totalSupplyBefore = multiwrap.totalSupply(tokenIdOfWrapped);

        vm.prank(tokenOwner);
        multiwrap.unwrapByShares(tokenIdOfWrapped, sharesToRedeem);

        assertEq(mockERC20.balanceOf(tokenOwner), ownerBalBefore + expectedRedeemAmount);
        assertEq(multiwrap.totalSupply(tokenIdOfWrapped), totalSupplyBefore - sharesToRedeem);
    }

    function test_unwrapByShares_revert_invalidTokenId() public {
        uint256 tokenIdOfWrapped = _setup_unwrapByShares();

        uint256 invalidId = multiwrap.nextTokenIdToMint();
        uint256 totalShares = multiwrap.totalShares(tokenIdOfWrapped);
        uint256 sharesToRedeem = (totalShares * 10) / 100; // 10%

        vm.expectRevert("invalid tokenId");

        vm.prank(tokenOwner);
        multiwrap.unwrapByShares(invalidId, sharesToRedeem);
    }

    function test_unwrapByShares_revert_insufficientShares() public {
        uint256 tokenIdOfWrapped = _setup_unwrapByShares();

        uint256 totalShares = multiwrap.totalShares(tokenIdOfWrapped);
        uint256 sharesToRedeem = (totalShares * 10) / 100; // 10%

        vm.prank(tokenOwner);
        multiwrap.safeTransferFrom(tokenOwner, deployer, tokenIdOfWrapped, totalShares, "");

        vm.expectRevert("unwrapping more than owned");

        vm.prank(tokenOwner);
        multiwrap.unwrapByShares(tokenIdOfWrapped, sharesToRedeem);
    }

    function test_unwrapByShares_revert_notOnlyERC20() public {
        uint256 tokenIdOfWrapped = _setup_unwrap();

        uint256 totalShares = multiwrap.totalShares(tokenIdOfWrapped);
        uint256 sharesToRedeem = (totalShares * 10) / 100; // 10%

        vm.expectRevert("cannot unwrap NFTs by shares");

        vm.prank(tokenOwner);
        multiwrap.unwrapByShares(tokenIdOfWrapped, sharesToRedeem);
    }

    function test_unwrapByShares_emit_Unwrapped() public {
        IMultiwrap.WrappedContents memory onlyERC20Wrapped = _get_onlyWrapERC20();
        uint256 tokenIdOfWrapped =_setup_unwrapByShares();

        uint256 totalShares = multiwrap.totalShares(tokenIdOfWrapped);
        uint256 sharesToRedeem = (totalShares * 10) / 100; // 10%

        vm.expectEmit(true, true, false, true);
        emit TokensUnwrapped(tokenOwner, tokenIdOfWrapped, sharesToRedeem, onlyERC20Wrapped);

        vm.prank(tokenOwner);
        multiwrap.unwrapByShares(tokenIdOfWrapped, sharesToRedeem);
    }

    //  =====   Attack vectors  =====
    /**
     *      - Re-entrancy on `unwrap` and `unwrapByShares`.
     *      - `unwrapByShares` should always honor the correct
     *         amount of shares.
     */
    
    MockERC20Reentrancy mockERC20Reentrancy;
    
    function _setup_unwrap_reentrancy() internal returns (uint256 tokenIdOfWrapped) {
        vm.startPrank(tokenOwner);

        mockERC20Reentrancy = new MockERC20Reentrancy(address(multiwrap));
        mockERC20Reentrancy.mint(tokenOwner, erc20AmountToWrap);

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

        IMultiwrap.WrappedContents memory onlyERC20Wrapped = _get_onlyWrapERC20Reentrancy();

        setApproval20(
            onlyERC20Wrapped.erc20AssetContracts, 
            onlyERC20Wrapped.erc20AmountsToWrap,
            true,
            tokenOwner,
            address(multiwrap)
        );

        uint256 sharesToMint = 10;
        string memory uriForShares = "ipfs://shares";

        tokenIdOfWrapped = multiwrap.nextTokenIdToMint();

        vm.prank(tokenOwner);
        multiwrap.wrap(onlyERC20Wrapped, sharesToMint, uriForShares);
    }
    function _get_onlyWrapERC20Reentrancy() internal view returns (IMultiwrap.WrappedContents memory onlyERC20Wrapped)  {

        address[] memory erc1155AssetContracts_;
        uint256[][] memory erc1155TokensToWrap_;
        uint256[][] memory erc1155AmountsToWrap_;

        address[] memory erc721AssetContracts_;
        uint256[][] memory erc721TokensToWrap_;
        
        address[] memory erc20AssetContracts_ = new address[](1);
        erc20AssetContracts_[0] = address(mockERC20Reentrancy);
        
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
    
    function test_unwrap_reentrancy() public {
        uint256 tokenIdOfWrapped = _setup_unwrap_reentrancy();

        mockERC20Reentrancy.setToReenter(true);

        vm.expectRevert("ReentrancyGuard: reentrant call");

        vm.prank(tokenOwner);
        multiwrap.unwrap(tokenIdOfWrapped);
    }

    function test_unwrapByShares_reentrancy() public {
        uint256 tokenIdOfWrapped = _setup_unwrap_reentrancy();

        uint256 totalShares = multiwrap.totalShares(tokenIdOfWrapped);
        uint256 sharesToRedeem = (totalShares * 10) / 100; // 10%

        mockERC20Reentrancy.setToReenter(true);

        vm.expectRevert("ReentrancyGuard: reentrant call");

        vm.prank(tokenOwner);
        multiwrap.unwrapByShares(tokenIdOfWrapped, sharesToRedeem);
    }

    function _setup_unwrapByShares_fuzz(uint256 _erc20AmountToWrap) internal returns (uint256 tokenIdOfWrapped) {
        vm.startPrank(tokenOwner);

        mockERC20 = new MockERC20();
        mockERC20.mint(tokenOwner, _erc20AmountToWrap);

        vm.stopPrank();

        IMultiwrap.WrappedContents memory wrappedContentsFuzz = _get_onlyWrapERC20_fuzz(_erc20AmountToWrap);
        emit log("hellobefore");
        setApproval20(
            wrappedContentsFuzz.erc20AssetContracts, 
            wrappedContentsFuzz.erc20AmountsToWrap,
            true,
            tokenOwner,
            address(multiwrap)
        );

        emit log("hello");

        uint256 sharesToMint = 10_000;
        string memory uriForShares = "ipfs://shares";

        tokenIdOfWrapped = multiwrap.nextTokenIdToMint();

        vm.prank(tokenOwner);
        multiwrap.wrap(wrappedContentsFuzz, sharesToMint, uriForShares);
    }

    function _get_onlyWrapERC20_fuzz(uint256 _erc20AmountToWrap) internal view returns (IMultiwrap.WrappedContents memory onlyERC20Wrapped)  {

        address[] memory erc1155AssetContracts_;
        uint256[][] memory erc1155TokensToWrap_;
        uint256[][] memory erc1155AmountsToWrap_;

        address[] memory erc721AssetContracts_;
        uint256[][] memory erc721TokensToWrap_;
        
        address[] memory erc20AssetContracts_ = new address[](1);
        erc20AssetContracts_[0] = address(mockERC20);
        
        uint256[] memory erc20AmountsToWrap_ = new uint256[](1);
        erc20AmountsToWrap_[0] = _erc20AmountToWrap;

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

    function test_unwrapByShares_fuzz(uint256 _erc20AmountToWrap, uint256 _sharesToRedeem) public {

        if(_erc20AmountToWrap == 0 || _sharesToRedeem == 0) {
            return;
        }

        uint256 tokenIdOfWrapped =_setup_unwrapByShares_fuzz(_erc20AmountToWrap);

        uint256 totalShares = multiwrap.totalShares(tokenIdOfWrapped);
        uint256 sharesToRedeem = _sharesToRedeem < totalShares ? _sharesToRedeem : _sharesToRedeem % totalShares;

        if(_erc20AmountToWrap % totalShares == 0) {
            uint256 expectedRedeemAmount = (erc20AmountToWrap * sharesToRedeem) / totalShares;
            uint256 ownerBalBefore = mockERC20.balanceOf(tokenOwner);
            uint256 totalSupplyBefore = multiwrap.totalSupply(tokenIdOfWrapped);

            vm.prank(tokenOwner);
            multiwrap.unwrapByShares(tokenIdOfWrapped, sharesToRedeem);

            assertEq(mockERC20.balanceOf(tokenOwner), ownerBalBefore + expectedRedeemAmount);
            assertEq(multiwrap.totalSupply(tokenIdOfWrapped), totalSupplyBefore - sharesToRedeem);
        } else {

            vm.expectRevert("cannot unwrap by shares");

            vm.prank(tokenOwner);
            multiwrap.unwrapByShares(tokenIdOfWrapped, sharesToRedeem);
        }
    }
}