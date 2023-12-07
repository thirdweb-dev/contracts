// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { Multiwrap } from "contracts/prebuilts/multiwrap/Multiwrap.sol";
import { ITokenBundle } from "contracts/extension/interface/ITokenBundle.sol";

// Test imports
import { MockERC20 } from "../mocks/MockERC20.sol";
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract MultiwrapBenchmarkTest is BaseTest {
    /// @dev Emitted when tokens are wrapped.
    event TokensWrapped(
        address indexed wrapper,
        address indexed recipientOfWrappedToken,
        uint256 indexed tokenIdOfWrappedToken,
        ITokenBundle.Token[] wrappedContents
    );

    /// @dev Emitted when tokens are unwrapped.
    event TokensUnwrapped(
        address indexed unwrapper,
        address indexed recipientOfWrappedContents,
        uint256 indexed tokenIdOfWrappedToken
    );

    /*///////////////////////////////////////////////////////////////
                                Setup
    //////////////////////////////////////////////////////////////*/

    Multiwrap internal multiwrap;

    Wallet internal tokenOwner;
    string internal uriForWrappedToken;
    ITokenBundle.Token[] internal wrappedContent;

    function setUp() public override {
        super.setUp();

        // Get target contract
        multiwrap = Multiwrap(payable(getContract("Multiwrap")));

        // Set test vars
        tokenOwner = getWallet();
        uriForWrappedToken = "ipfs://baseURI/";

        wrappedContent.push(
            ITokenBundle.Token({
                assetContract: address(erc20),
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 10 ether
            })
        );
        wrappedContent.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 0,
                totalAmount: 1
            })
        );
        wrappedContent.push(
            ITokenBundle.Token({
                assetContract: address(erc1155),
                tokenType: ITokenBundle.TokenType.ERC1155,
                tokenId: 0,
                totalAmount: 100
            })
        );

        // Mint tokens-to-wrap to `tokenOwner`
        erc20.mint(address(tokenOwner), 10 ether);
        erc721.mint(address(tokenOwner), 1);
        erc1155.mint(address(tokenOwner), 0, 100);

        // Token owner approves `Multiwrap` to transfer tokens.
        tokenOwner.setAllowanceERC20(address(erc20), address(multiwrap), type(uint256).max);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(multiwrap), true);
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(multiwrap), true);

        // Grant MINTER_ROLE / requisite wrapping permissions to `tokenOwer`
        vm.prank(deployer);
        multiwrap.grantRole(keccak256("MINTER_ROLE"), address(tokenOwner));
    }

    /*///////////////////////////////////////////////////////////////
                        Multiwrap benchmark
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_multiwrap_wrap() public {
        vm.pauseGasMetering();
        address recipient = address(0x123);
        vm.prank(address(tokenOwner));
        vm.resumeGasMetering();
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);
    }

    function test_benchmark_multiwrap_unwrap() public {
        vm.pauseGasMetering();
        // ===== setup: wrap tokens =====
        uint256 expectedIdForWrappedToken = multiwrap.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        multiwrap.wrap(wrappedContent, uriForWrappedToken, recipient);

        // ===== target test content =====

        vm.prank(recipient);
        vm.resumeGasMetering();
        multiwrap.unwrap(expectedIdForWrappedToken, recipient);
    }
}
