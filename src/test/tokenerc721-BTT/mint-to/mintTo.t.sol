// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC721 is TokenERC721 {}

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

contract TokenERC721Test_MintTo is BaseTest {
    address public implementation;
    address public proxy;
    address public caller;
    address public recipient;
    string public uri;

    MyTokenERC721 internal tokenContract;
    ERC721ReceiverCompliant internal erc721ReceiverContract;

    event MetadataUpdate(uint256 _tokenId);
    event TokensMinted(address indexed mintedTo, uint256 indexed tokenIdMinted, string uri);

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
        tokenContract.mintTo(recipient, uri);
    }

    modifier whenMinterRole() {
        vm.prank(deployer);
        tokenContract.grantRole(keccak256("MINTER_ROLE"), caller);
        _;
    }

    function test_mintTo_emptyUri() public whenMinterRole {
        vm.prank(caller);
        vm.expectRevert("empty uri.");
        tokenContract.mintTo(recipient, uri);
    }

    modifier whenNotEmptyUri() {
        uri = "ipfs://uri/1";
        _;
    }

    // ==================
    // ======= Test branch: recipient EOA
    // ==================

    function test_mintTo_EOA() public whenMinterRole whenNotEmptyUri {
        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        // mint
        vm.prank(caller);
        uint256 _tokenId = tokenContract.mintTo(recipient, uri);

        // check state after
        assertEq(_tokenId, _tokenIdToMint);
        assertEq(tokenContract.tokenURI(_tokenId), uri);
        assertEq(tokenContract.nextTokenIdToMint(), _tokenIdToMint + 1);
        assertEq(tokenContract.ownerOf(_tokenId), recipient);
    }

    function test_mintTo_EOA_MetadataUpdateEvent() public whenMinterRole whenNotEmptyUri {
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(false, false, false, true);
        emit MetadataUpdate(_tokenIdToMint);
        tokenContract.mintTo(recipient, uri);
    }

    function test_mintTo_EOA_TokensMintedEvent() public whenMinterRole whenNotEmptyUri {
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(true, true, false, true);
        emit TokensMinted(recipient, _tokenIdToMint, uri);
        tokenContract.mintTo(recipient, uri);
    }

    // ==================
    // ======= Test branch: recipient is a contract
    // ==================

    function test_mintTo_nonERC721ReceiverContract() public whenMinterRole whenNotEmptyUri {
        recipient = address(this);
        vm.prank(caller);
        vm.expectRevert();
        uint256 _tokenId = tokenContract.mintTo(recipient, uri);
    }

    modifier whenERC721Receiver() {
        recipient = address(erc721ReceiverContract);
        _;
    }

    function test_mintTo_contract() public whenMinterRole whenNotEmptyUri whenERC721Receiver {
        // state before
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        // mint
        vm.prank(caller);
        uint256 _tokenId = tokenContract.mintTo(recipient, uri);

        // check state after
        assertEq(_tokenId, _tokenIdToMint);
        assertEq(tokenContract.tokenURI(_tokenId), uri);
        assertEq(tokenContract.nextTokenIdToMint(), _tokenIdToMint + 1);
        assertEq(tokenContract.ownerOf(_tokenId), recipient);
    }

    function test_mintTo_contract_MetadataUpdateEvent() public whenMinterRole whenNotEmptyUri whenERC721Receiver {
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(false, false, false, true);
        emit MetadataUpdate(_tokenIdToMint);
        tokenContract.mintTo(recipient, uri);
    }

    function test_mintTo_contract_TokensMintedEvent() public whenMinterRole whenNotEmptyUri whenERC721Receiver {
        uint256 _tokenIdToMint = tokenContract.nextTokenIdToMint();

        vm.prank(caller);
        vm.expectEmit(true, true, false, true);
        emit TokensMinted(recipient, _tokenIdToMint, uri);
        tokenContract.mintTo(recipient, uri);
    }
}
