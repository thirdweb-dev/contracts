// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC1155 is TokenERC1155 {}

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

contract TokenERC1155Test_MintTo is BaseTest {
    address public implementation;
    address public proxy;
    address public caller;
    address public recipient;
    string public uri;
    uint256 public amount;

    MyTokenERC1155 internal tokenContract;
    ERC1155ReceiverCompliant internal erc1155ReceiverContract;

    event MetadataUpdate(uint256 _tokenId);
    event TokensMinted(address indexed mintedTo, uint256 indexed tokenIdMinted, string uri, uint256 quantityMinted);

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
        amount = 100;
        uri = "ipfs://uri";
    }

    function test_mintTo_notMinterRole() public {
        vm.prank(caller);
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(caller), 20),
                " is missing role ",
                Strings.toHexString(uint256(keccak256("MINTER_ROLE")), 32)
            )
        );
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);
    }

    modifier whenMinterRole() {
        vm.prank(deployer);
        tokenContract.grantRole(keccak256("MINTER_ROLE"), caller);
        _;
    }

    // ==================
    // ======= Test branch: `tokenId` input param is type(uint256).max
    // ==================

    function test_mintTo_maxTokenId_EOA() public whenMinterRole {
        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        // mint
        vm.prank(caller);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);

        // check state after
        assertEq(_tokenIdToMint, 0);
        assertEq(tokenContract.nextTokenIdToMint(), _tokenIdToMint + 1);
        assertEq(tokenContract.balanceOf(recipient, _tokenIdToMint), amount);
        assertEq(tokenContract.uri(_tokenIdToMint), uri);
    }

    function test_mintTo_maxTokenId_EOA_TokensMintedEvent() public whenMinterRole {
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(true, true, false, true);
        emit TokensMinted(recipient, _tokenIdToMint, uri, amount);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);
    }

    function test_mintTo_maxTokenId_EOA_MetadataUpdateEvent() public whenMinterRole {
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(false, false, false, true);
        emit MetadataUpdate(_tokenIdToMint);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);
    }

    function test_mintTo_maxTokenId_EOA_uriAlreadyPresent() public whenMinterRole {
        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(deployer);
        tokenContract.setTokenURI(_tokenIdToMint, "ipfs://uriOld");

        // mint
        vm.prank(caller);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);

        // check state after
        assertEq(_tokenIdToMint, 0);
        assertEq(tokenContract.nextTokenIdToMint(), _tokenIdToMint + 1);
        assertEq(tokenContract.balanceOf(recipient, _tokenIdToMint), amount);
        assertEq(tokenContract.uri(_tokenIdToMint), "ipfs://uriOld");
    }

    function test_mintTo_maxTokenId_nonERC1155ReceiverContract() public whenMinterRole {
        recipient = address(this);
        vm.prank(caller);
        vm.expectRevert();
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);
    }

    modifier whenERC1155Receiver() {
        recipient = address(erc1155ReceiverContract);
        _;
    }

    function test_mintTo_maxTokenId_contract() public whenMinterRole whenERC1155Receiver {
        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        // mint
        vm.prank(caller);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);

        // check state after
        assertEq(_tokenIdToMint, 0);
        assertEq(tokenContract.nextTokenIdToMint(), _tokenIdToMint + 1);
        assertEq(tokenContract.balanceOf(recipient, _tokenIdToMint), amount);
        assertEq(tokenContract.uri(_tokenIdToMint), uri);
    }

    function test_mintTo_maxTokenId_contract_TokensMintedEvent() public whenMinterRole whenERC1155Receiver {
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(true, true, false, true);
        emit TokensMinted(recipient, _tokenIdToMint, uri, amount);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);
    }

    function test_mintTo_maxTokenId_contract_MetadataUpdateEvent() public whenMinterRole whenERC1155Receiver {
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(false, false, false, true);
        emit MetadataUpdate(_tokenIdToMint);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);
    }

    function test_mintTo_maxTokenId_contract_uriAlreadyPresent() public whenMinterRole whenERC1155Receiver {
        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(deployer);
        tokenContract.setTokenURI(_tokenIdToMint, "ipfs://uriOld");

        // mint
        vm.prank(caller);
        tokenContract.mintTo(recipient, type(uint256).max, uri, amount);

        // check state after
        assertEq(_tokenIdToMint, 0);
        assertEq(tokenContract.nextTokenIdToMint(), _tokenIdToMint + 1);
        assertEq(tokenContract.balanceOf(recipient, _tokenIdToMint), amount);
        assertEq(tokenContract.uri(_tokenIdToMint), "ipfs://uriOld");
    }

    // ==================
    // ======= Test branch: `tokenId` input param is not type(uint256).max
    // ==================

    modifier whenNotMaxTokenId() {
        // pre-mint the first token (i.e. id 0), so that nextTokenIdToMint is 1, for this code path
        vm.prank(deployer);
        tokenContract.mintTo(deployer, type(uint256).max, "uri1", amount);
        _;
    }

    function test_mintTo_EOA_invalidId() public whenMinterRole whenNotMaxTokenId {
        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        // mint
        vm.prank(caller);
        vm.expectRevert("invalid id");
        tokenContract.mintTo(recipient, _tokenIdToMint, uri, amount);
    }

    modifier whenValidId() {
        _;
    }

    function test_mintTo_EOA() public whenMinterRole whenNotMaxTokenId whenValidId {
        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint() - 1;

        // mint
        vm.prank(caller);
        tokenContract.mintTo(recipient, _tokenIdToMint, uri, amount);

        // check state after
        assertEq(tokenContract.nextTokenIdToMint(), _tokenIdToMint + 1);
        assertEq(tokenContract.balanceOf(recipient, _tokenIdToMint), amount);
        assertEq(tokenContract.uri(_tokenIdToMint), "uri1");
    }

    function test_mintTo_EOA_TokensMintedEvent() public whenMinterRole whenNotMaxTokenId whenValidId {
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint() - 1;

        vm.prank(caller);
        vm.expectEmit(true, true, false, true);
        emit TokensMinted(recipient, _tokenIdToMint, "uri1", amount);
        tokenContract.mintTo(recipient, _tokenIdToMint, uri, amount);
    }

    function test_mintTo_nonERC1155ReceiverContract() public whenMinterRole whenNotMaxTokenId whenValidId {
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint() - 1;

        recipient = address(this);
        vm.prank(caller);
        vm.expectRevert();
        tokenContract.mintTo(recipient, _tokenIdToMint, uri, amount);
    }

    function test_mintTo_contract() public whenMinterRole whenNotMaxTokenId whenERC1155Receiver whenValidId {
        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint() - 1;

        // mint
        vm.prank(caller);
        tokenContract.mintTo(recipient, _tokenIdToMint, uri, amount);

        // check state after
        assertEq(tokenContract.nextTokenIdToMint(), _tokenIdToMint + 1);
        assertEq(tokenContract.balanceOf(recipient, _tokenIdToMint), amount);
        assertEq(tokenContract.uri(_tokenIdToMint), "uri1");
    }

    function test_mintTo_contract_TokensMintedEvent()
        public
        whenMinterRole
        whenNotMaxTokenId
        whenERC1155Receiver
        whenValidId
    {
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint() - 1;

        vm.prank(caller);
        vm.expectEmit(true, true, false, true);
        emit TokensMinted(recipient, _tokenIdToMint, "uri1", amount);
        tokenContract.mintTo(recipient, _tokenIdToMint, uri, amount);
    }
}
