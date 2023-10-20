// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC721 is TokenERC721 {}

contract TokenERC721Test_TokenURI is BaseTest {
    address public implementation;
    address public proxy;

    MyTokenERC721 internal tokenContract;

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
    }

    function test_tokenURI() public {
        uint256 _tokenId = 1;
        string memory _uri = "ipfs://uri/1";

        vm.prank(deployer);
        tokenContract.setTokenURI(_tokenId, _uri);

        assertEq(tokenContract.tokenURI(_tokenId), _uri);
    }
}
