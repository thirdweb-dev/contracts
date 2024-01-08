// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC20 is TokenERC20 {
    function setMintedUID(MintRequest calldata _req, bytes calldata _signature) external {
        verifyRequest(_req, _signature);
    }
}

contract ReentrantContract {
    fallback() external payable {
        TokenERC20.MintRequest memory _mintrequest;
        bytes memory _signature;
        MyTokenERC20(msg.sender).mintWithSignature(_mintrequest, _signature);
    }
}

contract TokenERC20Test_MintWithSignature is BaseTest {
    address public implementation;
    address public proxy;
    address public caller;
    address public recipient;

    MyTokenERC20 internal tokenContract;

    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    TokenERC20.MintRequest _mintrequest;

    event TokensMintedWithSignature(
        address indexed signer,
        address indexed mintedTo,
        TokenERC20.MintRequest mintRequest
    );

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC20());
        caller = getActor(1);
        recipient = getActor(2);

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = address(
            new TWProxy(
                implementation,
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
            )
        );

        tokenContract = MyTokenERC20(proxy);

        typehashMintRequest = keccak256(
            "MintRequest(address to,address primarySaleRecipient,uint256 quantity,uint256 price,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );
        nameHash = keccak256(bytes(NAME));
        versionHash = keccak256(bytes("1"));
        typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        domainSeparator = keccak256(
            abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(tokenContract))
        );

        // construct default mintrequest
        _mintrequest.to = recipient;
        _mintrequest.primarySaleRecipient = saleRecipient;
        _mintrequest.quantity = 100;
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
        TokenERC20.MintRequest memory _request,
        uint256 _privateKey
    ) internal view returns (bytes memory) {
        bytes memory encodedRequest = abi.encode(
            typehashMintRequest,
            _request.to,
            _request.primarySaleRecipient,
            _request.quantity,
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
        tokenContract.setMintedUID(_mintrequest, _signature);

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
        _mintrequest.price = 0;

        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.expectRevert("!Value");
        vm.prank(caller);
        tokenContract.mintWithSignature{ value: 1 }(_mintrequest, _signature);
    }

    modifier whenMsgValueZero() {
        _;
    }

    function test_mintWithSignature_zeroPrice()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotZeroQuantity
        whenMsgValueZero
    {
        _mintrequest.price = 0;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        // mint
        vm.prank(caller);
        tokenContract.mintWithSignature(_mintrequest, _signature);

        // check state after
        assertEq(tokenContract.balanceOf(recipient), _mintrequest.quantity);
    }

    function test_mintWithSignature_zeroPrice_TokensMintedWithSignatureEvent()
        public
        whenMinterRole
        whenUidNotUsed
        whenValidStartTimestamp
        whenValidEndTimestamp
        whenRecipientAddressNotZero
        whenNotZeroQuantity
        whenMsgValueZero
    {
        _mintrequest.price = 0;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(caller);
        vm.expectEmit(true, true, false, true);
        emit TokensMintedWithSignature(signer, _mintrequest.to, _mintrequest);
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
        whenNotZeroQuantity
        whenCorrectMsgValue
    {
        _mintrequest.price = 10;
        _mintrequest.currency = NATIVE_TOKEN;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        // mint
        vm.prank(caller);
        tokenContract.mintWithSignature{ value: _mintrequest.price }(_mintrequest, _signature);

        // check state after
        assertEq(tokenContract.balanceOf(recipient), _mintrequest.quantity);

        uint256 _platformFee = (_mintrequest.price * platformFeeBps) / 10_000;
        uint256 _saleProceeds = _mintrequest.price - _platformFee;
        assertEq(caller.balance, 1000 ether - _mintrequest.price);

        (address _platformFeeRecipient, ) = tokenContract.getPlatformFeeInfo();
        assertEq(_platformFeeRecipient.balance, _platformFee);
        assertEq(tokenContract.primarySaleRecipient().balance, _saleProceeds);
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
        _mintrequest.price = 10;
        _mintrequest.currency = NATIVE_TOKEN;
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(caller);
        vm.expectEmit(true, true, false, true);
        emit TokensMintedWithSignature(signer, _mintrequest.to, _mintrequest);
        tokenContract.mintWithSignature{ value: _mintrequest.price }(_mintrequest, _signature);
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
        whenNotZeroQuantity
        whenMsgValueZero
    {
        _mintrequest.price = 10;
        _mintrequest.currency = address(erc20);
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        // mint
        vm.prank(caller);
        tokenContract.mintWithSignature{ value: 0 }(_mintrequest, _signature);

        // check state after
        assertEq(tokenContract.balanceOf(recipient), _mintrequest.quantity);

        uint256 _platformFee = (_mintrequest.price * platformFeeBps) / 10_000;
        uint256 _saleProceeds = _mintrequest.price - _platformFee;
        assertEq(erc20.balanceOf(caller), 1000 ether - _mintrequest.price);
        (address _platformFeeRecipient, ) = tokenContract.getPlatformFeeInfo();
        assertEq(erc20.balanceOf(_platformFeeRecipient), _platformFee);
        assertEq(erc20.balanceOf(tokenContract.primarySaleRecipient()), _saleProceeds);
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
        _mintrequest.price = 10;
        _mintrequest.currency = address(erc20);
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(caller);
        vm.expectEmit(true, true, false, true);
        emit TokensMintedWithSignature(signer, _mintrequest.to, _mintrequest);
        tokenContract.mintWithSignature{ value: 0 }(_mintrequest, _signature);
    }

    // ==================
    // ======= Test branch: other cases
    // ==================
}
