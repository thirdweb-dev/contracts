// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC721 is TokenERC721 {
    function setMintedURI(MintRequest calldata _req, bytes calldata _signature) external {
        verifyRequest(_req, _signature);
    }
}

contract TokenERC721Test_Verify is BaseTest {
    address public implementation;
    address public proxy;

    MyTokenERC721 internal tokenContract;
    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    TokenERC721.MintRequest _mintrequest;

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC721());

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

    function test_verify_notMinterRole() public {
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        (bool _isValid, address _recoveredSigner) = tokenContract.verify(_mintrequest, _signature);

        assertFalse(_isValid);
        assertEq(_recoveredSigner, signer);
    }

    modifier whenMinterRole() {
        vm.prank(deployer);
        tokenContract.grantRole(keccak256("MINTER_ROLE"), signer);
        _;
    }

    function test_verify_invalidUID() public whenMinterRole {
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        // set state with this mintrequest and signature, marking the UID as used
        tokenContract.setMintedURI(_mintrequest, _signature);

        // pass the same UID mintrequest again
        (bool _isValid, address _recoveredSigner) = tokenContract.verify(_mintrequest, _signature);

        assertFalse(_isValid);
        assertEq(_recoveredSigner, signer);
    }

    modifier whenUidNotUsed() {
        _;
    }

    function test_verify() public whenMinterRole whenUidNotUsed {
        bytes memory _signature = signMintRequest(_mintrequest, privateKey);

        (bool _isValid, address _recoveredSigner) = tokenContract.verify(_mintrequest, _signature);

        assertTrue(_isValid);
        assertEq(_recoveredSigner, signer);
    }
}
