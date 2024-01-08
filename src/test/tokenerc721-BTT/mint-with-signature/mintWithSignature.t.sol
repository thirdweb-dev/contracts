// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC721 is TokenERC721 {
    function setMintedURI(MintRequest calldata _req, bytes calldata _signature) external {
        verifyRequest(_req, _signature);
    }
}

contract ERC721ReceiverCompliant is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external view virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract ReentrantContract {
    fallback() external payable {
        TokenERC721.MintRequest memory _mintrequest;
        bytes memory _signature;
        MyTokenERC721(msg.sender).mintWithSignature(_mintrequest, _signature);
    }
}

contract TokenERC721Test_MintWithSignature is BaseTest {
    address public implementation;
    address public proxy;
    address public caller;
    address public recipient;
    string public uri;

    MyTokenERC721 internal tokenContract;
    ERC721ReceiverCompliant internal erc721ReceiverContract;

    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    TokenERC721.MintRequest _mintrequest;

    event MetadataUpdate(uint256 _tokenId);
    event TokensMinted(address indexed mintedTo, uint256 indexed tokenIdMinted, string uri);
    event TokensMintedWithSignature(
        address indexed signer,
        address indexed mintedTo,
        uint256 indexed tokenIdMinted,
        TokenERC721.MintRequest mintRequest
    );

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC721());
        erc721ReceiverContract = new ERC721ReceiverCompliant();
        caller = getActor(1);
        recipient = getActor(2);

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = address(
            new TWProxy(
                implementation,
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
            )
        );

        tokenContract = MyTokenERC721(proxy);

        typehashMintRequest = keccak256(
            "MintRequest(address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,string uri,uint256 price,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );
        nameHash = keccak256(bytes("TokenERC721"));
        versionHash = keccak256(bytes("1"));
        typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        domainSeparator = keccak256(
            abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(tokenContract))
        );

        // construct default mintrequest
        _mintrequest.to = address(0x1234);
        _mintrequest.royaltyRecipient = royaltyRecipient;
        _mintrequest.royaltyBps = royaltyBps;
        _mintrequest.primarySaleRecipient = saleRecipient;
        _mintrequest.uri = "ipfs://";
        _mintrequest.price = 0;
        _mintrequest.currency = address(0);
        _mintrequest.validityStartTimestamp = 0;
        _mintrequest.validityEndTimestamp = 2000;
        _mintrequest.uid = bytes32(0);

        erc20.mint(deployer, 1_000 ether);
        vm.deal(deployer, 1_000 ether);
        erc20.mint(caller, 1_000 ether);
        vm.deal(caller, 1_000 ether);

        vm.startPrank(deployer);
        erc20.approve(address(tokenContract), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(caller);
        erc20.approve(address(tokenContract), type(uint256).max);
        vm.stopPrank();
    }

    function signMintRequest(
        TokenERC721.MintRequest memory _request,
        uint256 _privateKey
    ) internal view returns (bytes memory) {
        bytes memory encodedRequest = abi.encode(
            typehashMintRequest,
            _request.to,
            _request.royaltyRecipient,
            _request.royaltyBps,
            _request.primarySaleRecipient,
            keccak256(bytes(_request.uri)),
            _request.price,
            _request.currency,
            _request.validityStartTimestamp,
            _request.validityEndTimestamp,
            _request.uid
        );
        bytes32 structHash = keccak256(encodedRequest);
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, typedDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        return sig;
    }

    function test_mintWithSignature_notMinterRole() public {
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(caller);
        vm.expectRevert("invalid signature");
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    modifier whenMinterRole() {
        vm.prank(deployer);
        tokenContract.grantRole(keccak256("MINTER_ROLE"), signer);
        _;
    }

    function test_mintWithSignature_invalidUID() public whenMinterRole {
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        // set state with this mintrequest and signature, marking the UID as used
        tokenContract.setMintedURI(_mintrequest, _signature);

        // pass the same UID mintrequest again
        vm.prank(caller);
        vm.expectRevert("invalid signature");
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    modifier whenUidNotUsed() {
        _;
    }

    function test_mintWithSignature_invalidStartTimestamp() public whenMinterRole whenUidNotUsed {
        _mintrequest.validityStartTimestamp = uint128(block.timestamp + 1);

        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.expectRevert("request expired");
        vm.prank(caller);
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    modifier whenValidStartTimestamp() {
        _;
    }

    function test_mintWithSignature_invalidEndTimestamp() public whenMinterRole whenUidNotUsed whenValidStartTimestamp {
        _mintrequest.validityEndTimestamp = uint128(block.timestamp - 1);

        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.expectRevert("request expired");
        vm.prank(caller);
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    modifier whenValidEndTimestamp() {
        _;
    }

    function test_mintWithSignature_recipientAddressZero()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
    {
        _mintrequest.to = address(0);

        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.expectRevert("recipient undefined");
        vm.prank(caller);
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    modifier whenRecipientAddressNotZero() {
        _;
    }

    function test_mintWithSignature_emptyUri()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
    {
        _mintrequest.uri = "";

        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.expectRevert("empty uri.");
        vm.prank(caller);
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    modifier whenNotEmptyUri() {
        _;
    }

    // ==================
    // ======= Test branch: when mint price is zero
    // ==================

    function test_mintWithSignature_zeroPrice_msgValueNonZero()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
    {
        _mintrequest.price = 0;

        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.expectRevert("!Value");
        vm.prank(caller);
        tokenContract.mintWithSignature{ value: 1 }(_mintrequest, _signature);
    }

    modifier whenMsgValueZero() {
        _;
    }

    function test_mintWithSignature_zeroPrice_EOA()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
        whenMsgValueZero
    {
        _mintrequest.price = 0;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        // mint
        vm.prank(caller);
        uint256 _tokenId = tokenContract.mintWithSignature(_mintrequest, _signature);

        // check state after
        assertEq(_tokenId, _tokenIdToMint);
        assertEq(tokenContract.tokenURI(_tokenId), _mintrequest.uri);
        assertEq(tokenContract.nextTokenIdToMint(), _tokenIdToMint + 1);
        assertEq(tokenContract.ownerOf(_tokenId), _mintrequest.to);
    }

    function test_mintWithSignature_zeroPrice_EOA_MetadataUpdateEvent()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
        whenMsgValueZero
    {
        _mintrequest.price = 0;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(false, false, false, true);
        emit MetadataUpdate(_tokenIdToMint);
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    function test_mintWithSignature_zeroPrice_EOA_TokensMintedWithSignatureEvent()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
        whenMsgValueZero
    {
        _mintrequest.price = 0;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(true, true, false, true);
        emit TokensMintedWithSignature(signer, _mintrequest.to, _tokenIdToMint, _mintrequest);
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    function test_mintWithSignature_zeroPrice_nonERC721ReceiverContract()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
        whenMsgValueZero
    {
        _mintrequest.price = 0;
        _mintrequest.to = address(this);
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        // mint
        vm.prank(caller);
        vm.expectRevert();
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    modifier whenERC721Receiver() {
        _mintrequest.to = address(erc721ReceiverContract);
        _;
    }

    function test_mintWithSignature_zeroPrice_contract()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
        whenMsgValueZero
        whenERC721Receiver
    {
        _mintrequest.price = 0;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        // mint
        vm.prank(caller);
        uint256 _tokenId = tokenContract.mintWithSignature(_mintrequest, _signature);

        // check state after
        assertEq(_tokenId, _tokenIdToMint);
        assertEq(tokenContract.tokenURI(_tokenId), _mintrequest.uri);
        assertEq(tokenContract.nextTokenIdToMint(), _tokenIdToMint + 1);
        assertEq(tokenContract.ownerOf(_tokenId), _mintrequest.to);
    }

    function test_mintWithSignature_zeroPrice_contract_MetadataUpdateEvent()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
        whenMsgValueZero
        whenERC721Receiver
    {
        _mintrequest.price = 0;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(false, false, false, true);
        emit MetadataUpdate(_tokenIdToMint);
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    function test_mintWithSignature_zeroPrice_contract_TokensMintedWithSignatureEvent()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
        whenMsgValueZero
        whenERC721Receiver
    {
        _mintrequest.price = 0;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(true, true, true, true);
        emit TokensMintedWithSignature(signer, _mintrequest.to, _tokenIdToMint, _mintrequest);
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    // ==================
    // ======= Test branch: when mint price is not zero
    // ==================

    function test_mintWithSignature_nonZeroPrice_nativeToken_incorrectMsgValue()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
    {
        _mintrequest.price = 10;
        _mintrequest.currency = NATIVE_TOKEN;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        uint256 incorrectTotalPrice = (_mintrequest.price) + 1;

        vm.expectRevert("must send total price.");
        vm.prank(caller);
        tokenContract.mintWithSignature{ value: incorrectTotalPrice }(_mintrequest, _signature);
    }

    modifier whenCorrectMsgValue() {
        _;
    }

    function test_mintWithSignature_nonZeroPrice_nativeToken()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
        whenCorrectMsgValue
    {
        _mintrequest.price = 10;
        _mintrequest.currency = NATIVE_TOKEN;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        // mint
        vm.prank(caller);
        uint256 _tokenId = tokenContract.mintWithSignature{ value: _mintrequest.price }(_mintrequest, _signature);

        // check state after
        assertEq(_tokenId, _tokenIdToMint);
        assertEq(tokenContract.tokenURI(_tokenId), _mintrequest.uri);
        assertEq(tokenContract.nextTokenIdToMint(), _tokenIdToMint + 1);
        assertEq(tokenContract.ownerOf(_tokenId), _mintrequest.to);

        uint256 _platformFee = (_mintrequest.price * platformFeeBps) / 10_000;
        uint256 _saleProceeds = _mintrequest.price - _platformFee;
        assertEq(caller.balance, 1000 ether - _mintrequest.price);
        assertEq(tokenContract.platformFeeRecipient().balance, _platformFee);
        assertEq(tokenContract.primarySaleRecipient().balance, _saleProceeds);
    }

    function test_mintWithSignature_nonZeroPrice_nativeToken_MetadataUpdateEvent()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
        whenCorrectMsgValue
    {
        _mintrequest.price = 10;
        _mintrequest.currency = NATIVE_TOKEN;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(false, false, false, true);
        emit MetadataUpdate(_tokenIdToMint);
        tokenContract.mintWithSignature{ value: _mintrequest.price }(_mintrequest, _signature);
    }

    function test_mintWithSignature_nonZeroPrice_nativeToken_TokensMintedWithSignatureEvent()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
        whenCorrectMsgValue
    {
        _mintrequest.price = 10;
        _mintrequest.currency = NATIVE_TOKEN;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(true, true, true, true);
        emit TokensMintedWithSignature(signer, _mintrequest.to, _tokenIdToMint, _mintrequest);
        tokenContract.mintWithSignature{ value: _mintrequest.price }(_mintrequest, _signature);
    }

    function test_mintWithSignature_nonZeroPrice_ERC20_nonZeroMsgValue()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
    {
        _mintrequest.price = 10;
        _mintrequest.currency = address(erc20);
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.expectRevert("msg value not zero");
        vm.prank(caller);
        tokenContract.mintWithSignature{ value: 1 }(_mintrequest, _signature);
    }

    function test_mintWithSignature_nonZeroPrice_ERC20()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
        whenMsgValueZero
    {
        _mintrequest.price = 10;
        _mintrequest.currency = address(erc20);
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        // mint
        vm.prank(caller);
        uint256 _tokenId = tokenContract.mintWithSignature{ value: 0 }(_mintrequest, _signature);

        // check state after
        assertEq(_tokenId, _tokenIdToMint);
        assertEq(tokenContract.tokenURI(_tokenId), _mintrequest.uri);
        assertEq(tokenContract.nextTokenIdToMint(), _tokenIdToMint + 1);
        assertEq(tokenContract.ownerOf(_tokenId), _mintrequest.to);

        uint256 _platformFee = (_mintrequest.price * platformFeeBps) / 10_000;
        uint256 _saleProceeds = _mintrequest.price - _platformFee;
        assertEq(erc20.balanceOf(caller), 1000 ether - _mintrequest.price);
        assertEq(erc20.balanceOf(tokenContract.platformFeeRecipient()), _platformFee);
        assertEq(erc20.balanceOf(tokenContract.primarySaleRecipient()), _saleProceeds);
    }

    function test_mintWithSignature_nonZeroPrice_ERC20_MetadataUpdateEvent()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
        whenMsgValueZero
    {
        _mintrequest.price = 10;
        _mintrequest.currency = address(erc20);
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(false, false, false, true);
        emit MetadataUpdate(_tokenIdToMint);
        tokenContract.mintWithSignature{ value: 0 }(_mintrequest, _signature);
    }

    function test_mintWithSignature_nonZeroPrice_ERC20_TokensMintedWithSignatureEvent()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
        whenMsgValueZero
    {
        _mintrequest.price = 10;
        _mintrequest.currency = address(erc20);
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(true, true, true, true);
        emit TokensMintedWithSignature(signer, _mintrequest.to, _tokenIdToMint, _mintrequest);
        tokenContract.mintWithSignature{ value: 0 }(_mintrequest, _signature);
    }

    // ==================
    // ======= Test branch: other cases
    // ==================

    function test_mintWithSignature_nonZeroRoyaltyRecipient()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
        whenMsgValueZero
    {
        _mintrequest.price = 0;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(caller);
        uint256 _tokenId = tokenContract.mintWithSignature(_mintrequest, _signature);

        (address _royaltyRecipient, uint16 _royaltyBps) = tokenContract.getRoyaltyInfoForToken(_tokenId);
        assertEq(_royaltyRecipient, royaltyRecipient);
        assertEq(_royaltyBps, royaltyBps);
    }

    function test_mintWithSignature_royaltyRecipientZeroAddress()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
        whenMsgValueZero
    {
        _mintrequest.price = 0;
        _mintrequest.royaltyRecipient = address(0);
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(caller);
        uint256 _tokenId = tokenContract.mintWithSignature(_mintrequest, _signature);

        (address _royaltyRecipient, uint16 _royaltyBps) = tokenContract.getRoyaltyInfoForToken(_tokenId);
        (address _defaultRoyaltyRecipient, uint16 _defaultRoyaltyBps) = tokenContract.getDefaultRoyaltyInfo();
        assertEq(_royaltyRecipient, _defaultRoyaltyRecipient);
        assertEq(_royaltyBps, _defaultRoyaltyBps);
    }

    function test_mintWithSignature_reentrantRecipientContract()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotEmptyUri
        whenMsgValueZero
    {
        _mintrequest.price = 0;
        _mintrequest.to = address(new ReentrantContract());
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(caller);
        vm.expectRevert("ReentrancyGuard: reentrant call");
        uint256 _tokenId = tokenContract.mintWithSignature(_mintrequest, _signature);
    }
}
