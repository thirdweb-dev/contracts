// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";
import { IPlatformFee } from "contracts/extension/interface/IPlatformFee.sol";

contract MyTokenERC1155 is TokenERC1155 {
    function setMintedURI(MintRequest calldata _req, bytes calldata _signature) external {
        verifyRequest(_req, _signature);
    }
}

contract ERC1155ReceiverCompliant is IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external view virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {}
}

contract ReentrantContract {
    fallback() external payable {
        TokenERC1155.MintRequest memory _mintrequest;
        bytes memory _signature;
        MyTokenERC1155(msg.sender).mintWithSignature(_mintrequest, _signature);
    }
}

contract TokenERC1155Test_MintWithSignature is BaseTest {
    address public implementation;
    address public proxy;
    address public caller;
    address public recipient;
    string public uri;

    MyTokenERC1155 internal tokenContract;
    ERC1155ReceiverCompliant internal erc1155ReceiverContract;

    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    TokenERC1155.MintRequest _mintrequest;

    event MetadataUpdate(uint256 _tokenId);
    event TokensMinted(address indexed mintedTo, uint256 indexed tokenIdMinted, string uri);
    event TokensMintedWithSignature(
        address indexed signer,
        address indexed mintedTo,
        uint256 indexed tokenIdMinted,
        TokenERC1155.MintRequest mintRequest
    );

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC1155());
        erc1155ReceiverContract = new ERC1155ReceiverCompliant();
        caller = getActor(1);
        recipient = getActor(2);

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = address(
            new TWProxy(
                implementation,
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
            )
        );

        tokenContract = MyTokenERC1155(proxy);

        typehashMintRequest = keccak256(
            "MintRequest(address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,uint256 tokenId,string uri,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );
        nameHash = keccak256(bytes("TokenERC1155"));
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
        _mintrequest.tokenId = type(uint256).max;
        _mintrequest.uri = "ipfs://";
        _mintrequest.quantity = 100;
        _mintrequest.pricePerToken = 0;
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
        TokenERC1155.MintRequest memory _request,
        uint256 _privateKey
    ) internal view returns (bytes memory) {
        bytes memory encodedRequest = bytes.concat(
            abi.encode(
                typehashMintRequest,
                _request.to,
                _request.royaltyRecipient,
                _request.royaltyBps,
                _request.primarySaleRecipient,
                _request.tokenId,
                keccak256(bytes(_request.uri))
            ),
            abi.encode(
                _request.quantity,
                _request.pricePerToken,
                _request.currency,
                _request.validityStartTimestamp,
                _request.validityEndTimestamp,
                _request.uid
            )
        );
        bytes32 structHash = keccak256(encodedRequest);
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, typedDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        return sig;
    }

    // ==================
    // ======= Assume _req.tokenId input is type(uint256).max and platform fee type is Bps
    // ==================

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

    function test_mintWithSignature_zeroQuantity()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
    {
        _mintrequest.quantity = 0;

        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.expectRevert("zero quantity");
        vm.prank(caller);
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    modifier whenNotZeroQuantity() {
        _mintrequest.quantity = 100;
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
        whenNotZeroQuantity
    {
        _mintrequest.pricePerToken = 0;

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
        whenNotZeroQuantity
        whenMsgValueZero
    {
        _mintrequest.pricePerToken = 0;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        // mint
        vm.prank(caller);
        tokenContract.mintWithSignature(_mintrequest, _signature);

        // check state after
        assertEq(tokenContract.nextTokenIdToMint(), _tokenIdToMint + 1);
        assertEq(tokenContract.balanceOf(_mintrequest.to, _tokenIdToMint), _mintrequest.quantity);
        assertEq(tokenContract.uri(_tokenIdToMint), _mintrequest.uri);
        assertEq(tokenContract.totalSupply(_tokenIdToMint), _mintrequest.quantity);
    }

    function test_mintWithSignature_zeroPrice_EOA_MetadataUpdateEvent()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotZeroQuantity
        whenMsgValueZero
    {
        _mintrequest.pricePerToken = 0;
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
        whenNotZeroQuantity
        whenMsgValueZero
    {
        _mintrequest.pricePerToken = 0;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(true, true, false, true);
        emit TokensMintedWithSignature(signer, _mintrequest.to, _tokenIdToMint, _mintrequest);
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    function test_mintWithSignature_zeroPrice_nonERC1155ReceiverContract()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotZeroQuantity
        whenMsgValueZero
    {
        _mintrequest.pricePerToken = 0;
        _mintrequest.to = address(this);
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        // mint
        vm.prank(caller);
        vm.expectRevert();
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    modifier whenERC1155Receiver() {
        _mintrequest.to = address(erc1155ReceiverContract);
        _;
    }

    function test_mintWithSignature_zeroPrice_contract()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotZeroQuantity
        whenMsgValueZero
        whenERC1155Receiver
    {
        _mintrequest.pricePerToken = 0;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        // mint
        vm.prank(caller);
        tokenContract.mintWithSignature(_mintrequest, _signature);

        // check state after
        assertEq(tokenContract.nextTokenIdToMint(), _tokenIdToMint + 1);
        assertEq(tokenContract.balanceOf(_mintrequest.to, _tokenIdToMint), _mintrequest.quantity);
        assertEq(tokenContract.uri(_tokenIdToMint), _mintrequest.uri);
        assertEq(tokenContract.totalSupply(_tokenIdToMint), _mintrequest.quantity);
    }

    function test_mintWithSignature_zeroPrice_contract_MetadataUpdateEvent()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotZeroQuantity
        whenMsgValueZero
        whenERC1155Receiver
    {
        _mintrequest.pricePerToken = 0;
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
        whenNotZeroQuantity
        whenMsgValueZero
        whenERC1155Receiver
    {
        _mintrequest.pricePerToken = 0;
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
        whenNotZeroQuantity
    {
        _mintrequest.pricePerToken = 10;
        _mintrequest.currency = NATIVE_TOKEN;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        uint256 incorrectTotalPrice = (_mintrequest.pricePerToken * _mintrequest.quantity) + 1;

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
        whenNotZeroQuantity
        whenCorrectMsgValue
    {
        _mintrequest.pricePerToken = 10;
        _mintrequest.currency = NATIVE_TOKEN;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        uint256 totalPrice = (_mintrequest.pricePerToken * _mintrequest.quantity);

        // mint
        vm.prank(caller);
        tokenContract.mintWithSignature{ value: totalPrice }(_mintrequest, _signature);

        // check state after
        assertEq(tokenContract.nextTokenIdToMint(), _tokenIdToMint + 1);
        assertEq(tokenContract.balanceOf(_mintrequest.to, _tokenIdToMint), _mintrequest.quantity);
        assertEq(tokenContract.uri(_tokenIdToMint), _mintrequest.uri);
        assertEq(tokenContract.totalSupply(_tokenIdToMint), _mintrequest.quantity);

        uint256 _platformFee = (totalPrice * platformFeeBps) / 10_000;
        uint256 _saleProceeds = totalPrice - _platformFee;
        assertEq(caller.balance, 1000 ether - totalPrice);
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
        whenNotZeroQuantity
        whenCorrectMsgValue
    {
        _mintrequest.pricePerToken = 10;
        _mintrequest.currency = NATIVE_TOKEN;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(false, false, false, true);
        emit MetadataUpdate(_tokenIdToMint);
        tokenContract.mintWithSignature{ value: _mintrequest.pricePerToken * _mintrequest.quantity }(
            _mintrequest,
            _signature
        );
    }

    function test_mintWithSignature_nonZeroPrice_nativeToken_TokensMintedWithSignatureEvent()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotZeroQuantity
        whenCorrectMsgValue
    {
        _mintrequest.pricePerToken = 10;
        _mintrequest.currency = NATIVE_TOKEN;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(true, true, true, true);
        emit TokensMintedWithSignature(signer, _mintrequest.to, _tokenIdToMint, _mintrequest);
        tokenContract.mintWithSignature{ value: _mintrequest.pricePerToken * _mintrequest.quantity }(
            _mintrequest,
            _signature
        );
    }

    function test_mintWithSignature_nonZeroPrice_ERC20_nonZeroMsgValue()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotZeroQuantity
    {
        _mintrequest.pricePerToken = 10;
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
        whenNotZeroQuantity
        whenMsgValueZero
    {
        _mintrequest.pricePerToken = 10;
        _mintrequest.currency = address(erc20);
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        uint256 totalPrice = (_mintrequest.pricePerToken * _mintrequest.quantity);

        // mint
        vm.prank(caller);
        tokenContract.mintWithSignature{ value: 0 }(_mintrequest, _signature);

        // check state after
        assertEq(tokenContract.nextTokenIdToMint(), _tokenIdToMint + 1);
        assertEq(tokenContract.balanceOf(_mintrequest.to, _tokenIdToMint), _mintrequest.quantity);
        assertEq(tokenContract.uri(_tokenIdToMint), _mintrequest.uri);
        assertEq(tokenContract.totalSupply(_tokenIdToMint), _mintrequest.quantity);

        uint256 _platformFee = (totalPrice * platformFeeBps) / 10_000;
        uint256 _saleProceeds = totalPrice - _platformFee;
        assertEq(erc20.balanceOf(caller), 1000 ether - totalPrice);
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
        whenNotZeroQuantity
        whenMsgValueZero
    {
        _mintrequest.pricePerToken = 10;
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
        whenNotZeroQuantity
        whenMsgValueZero
    {
        _mintrequest.pricePerToken = 10;
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
        whenNotZeroQuantity
        whenMsgValueZero
    {
        _mintrequest.pricePerToken = 0;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(caller);
        tokenContract.mintWithSignature(_mintrequest, _signature);

        (address _royaltyRecipient, uint16 _royaltyBps) = tokenContract.getRoyaltyInfoForToken(0);
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
        whenNotZeroQuantity
        whenMsgValueZero
    {
        _mintrequest.pricePerToken = 0;
        _mintrequest.royaltyRecipient = address(0);
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(caller);
        tokenContract.mintWithSignature(_mintrequest, _signature);

        (address _royaltyRecipient, uint16 _royaltyBps) = tokenContract.getRoyaltyInfoForToken(0);
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
        whenNotZeroQuantity
        whenMsgValueZero
    {
        _mintrequest.pricePerToken = 0;
        _mintrequest.to = address(new ReentrantContract());
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(caller);
        vm.expectRevert("ReentrancyGuard: reentrant call");
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    function test_mintWithSignature_nonZeroPrice_flatFee_exceedsTotalPrice()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotZeroQuantity
        whenMsgValueZero
    {
        vm.startPrank(deployer);
        tokenContract.setPlatformFeeType(IPlatformFee.PlatformFeeType.Flat);
        tokenContract.setFlatPlatformFeeInfo(platformFeeRecipient, 100 ether);
        vm.stopPrank();

        _mintrequest.pricePerToken = 10;
        _mintrequest.currency = address(erc20);
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        uint256 totalPrice = (_mintrequest.pricePerToken * _mintrequest.quantity);

        // mint
        vm.prank(caller);
        vm.expectRevert("price less than platform fee");
        tokenContract.mintWithSignature{ value: 0 }(_mintrequest, _signature);
    }

    function test_mintWithSignature_nonZeroPrice_flatFee()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotZeroQuantity
        whenMsgValueZero
    {
        vm.prank(deployer);
        tokenContract.setPlatformFeeType(IPlatformFee.PlatformFeeType.Flat);

        _mintrequest.pricePerToken = 10;
        _mintrequest.currency = address(erc20);
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        uint256 totalPrice = (_mintrequest.pricePerToken * _mintrequest.quantity);

        // mint
        vm.prank(caller);
        tokenContract.mintWithSignature{ value: 0 }(_mintrequest, _signature);

        // check state after
        assertEq(tokenContract.nextTokenIdToMint(), _tokenIdToMint + 1);
        assertEq(tokenContract.balanceOf(_mintrequest.to, _tokenIdToMint), _mintrequest.quantity);
        assertEq(tokenContract.uri(_tokenIdToMint), _mintrequest.uri);
        assertEq(tokenContract.totalSupply(_tokenIdToMint), _mintrequest.quantity);

        (, uint256 _platformFee) = tokenContract.getFlatPlatformFeeInfo();
        uint256 _saleProceeds = totalPrice - _platformFee;
        assertEq(erc20.balanceOf(caller), 1000 ether - totalPrice);
        assertEq(erc20.balanceOf(tokenContract.platformFeeRecipient()), _platformFee);
        assertEq(erc20.balanceOf(tokenContract.primarySaleRecipient()), _saleProceeds);
    }

    modifier whenNotMaxTokenId() {
        // pre-mint the first token (i.e. id 0), so that nextTokenIdToMint is 1, for this code path
        vm.prank(deployer);
        tokenContract.mintTo(deployer, type(uint256).max, "uri1", 10);
        _;
    }

    function test_mintWithSignature_nonZeroPrice_notMaxTokenId_invalidId()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotZeroQuantity
        whenMsgValueZero
        whenNotMaxTokenId
    {
        vm.prank(deployer);
        tokenContract.setPlatformFeeType(IPlatformFee.PlatformFeeType.Flat);

        _mintrequest.pricePerToken = 10;
        _mintrequest.currency = address(erc20);
        _mintrequest.tokenId = 1;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(caller);
        vm.expectRevert("invalid id");
        tokenContract.mintWithSignature{ value: 0 }(_mintrequest, _signature);
    }

    modifier whenValidId() {
        _;
    }

    function test_mintWithSignature_nonZeroPrice_notMaxTokenId()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotZeroQuantity
        whenMsgValueZero
        whenNotMaxTokenId
        whenValidId
    {
        vm.prank(deployer);
        tokenContract.setPlatformFeeType(IPlatformFee.PlatformFeeType.Flat);

        _mintrequest.pricePerToken = 10;
        _mintrequest.currency = address(erc20);
        _mintrequest.tokenId = 0;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint() - 1;

        uint256 totalPrice = (_mintrequest.pricePerToken * _mintrequest.quantity);

        // mint
        vm.prank(caller);
        tokenContract.mintWithSignature{ value: 0 }(_mintrequest, _signature);

        // check state after
        assertEq(tokenContract.nextTokenIdToMint(), _tokenIdToMint + 1);
        assertEq(tokenContract.balanceOf(_mintrequest.to, _tokenIdToMint), _mintrequest.quantity);
        assertEq(tokenContract.uri(_tokenIdToMint), "uri1");
        assertEq(tokenContract.totalSupply(_tokenIdToMint), _mintrequest.quantity + 10);
    }
}
