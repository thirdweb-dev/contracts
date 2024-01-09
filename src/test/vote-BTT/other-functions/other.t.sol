// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";
import { IStaking721 } from "contracts/extension/interface/IStaking721.sol";
import { IERC2981 } from "contracts/eip/interface/IERC2981.sol";

import "@openzeppelin/contracts-upgradeable/governance/GovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";
import { ERC20Vote } from "contracts/base/ERC20Vote.sol";

contract MyVoteERC20 is VoteERC20 {}

contract VoteERC20Test_OtherFunctions is BaseTest {
    address payable public implementation;
    address payable public proxy;

    address public token;
    uint256 public initialVotingDelay;
    uint256 public initialVotingPeriod;
    uint256 public initialProposalThreshold;
    uint256 public initialVoteQuorumFraction;

    MyVoteERC20 public voteContract;

    function setUp() public override {
        super.setUp();

        // Deploy voting token
        vm.prank(deployer);
        token = address(new ERC20Vote(deployer, "Voting VoteERC20", "VT"));

        // Voting param initial values
        initialVotingDelay = 1;
        initialVotingPeriod = 100;
        initialProposalThreshold = 10;
        initialVoteQuorumFraction = 1;

        // Deploy implementation.
        implementation = payable(address(new MyVoteERC20()));

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = payable(
            address(
                new TWProxy(
                    implementation,
                    abi.encodeCall(
                        VoteERC20.initialize,
                        (
                            NAME,
                            CONTRACT_URI,
                            forwarders(),
                            token,
                            initialVotingDelay,
                            initialVotingPeriod,
                            initialProposalThreshold,
                            initialVoteQuorumFraction
                        )
                    )
                )
            )
        );

        voteContract = MyVoteERC20(proxy);
    }

    function test_contractType() public {
        assertEq(voteContract.contractType(), bytes32("VoteERC20"));
    }

    function test_contractVersion() public {
        assertEq(voteContract.contractVersion(), uint8(1));
    }

    function test_supportsInterface() public {
        assertTrue(voteContract.supportsInterface(type(IERC165).interfaceId));
        assertTrue(voteContract.supportsInterface(type(IERC165Upgradeable).interfaceId));
        assertTrue(voteContract.supportsInterface(type(IERC721ReceiverUpgradeable).interfaceId));
        assertTrue(voteContract.supportsInterface(type(IERC1155ReceiverUpgradeable).interfaceId));
        // assertTrue(voteContract.supportsInterface(type(IGovernorUpgradeable).interfaceId));

        // false for other not supported interfaces
        assertFalse(voteContract.supportsInterface(type(IStaking721).interfaceId));
    }
}
