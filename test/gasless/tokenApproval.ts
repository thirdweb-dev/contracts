// Test imports
import { ethers } from "hardhat";
import { expect } from "chai";

// Types
import { BigNumber, ContractFactory } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { PermitCoin } from "../../typechain/PermitCoin";

// EIP-2612 Signature
import { signERC2612Permit } from 'eth-permit';

describe("ERC20Permit approve spending via signature", function() {
  
  // Get signers
  let deployer: SignerWithAddress;
  let owner: SignerWithAddress;
  let spender: SignerWithAddress;
  let receiver: SignerWithAddress;
  let relayer: SignerWithAddress;

  // Get contract
  let erc20PermitToken: PermitCoin;

  // Params
  const tokenAmount: BigNumber = ethers.utils.parseEther("1");

  before(async () => {

    // Signers
    const signers: SignerWithAddress[] = await ethers.getSigners(); 
    [deployer, owner, spender, receiver, relayer] = signers;

    // Contract
    const erc20PermitToken_factory: ContractFactory = await ethers.getContractFactory("PermitCoin");
    erc20PermitToken = await erc20PermitToken_factory.connect(deployer).deploy() as PermitCoin;

    // Mint tokens to owner
    await erc20PermitToken.connect(owner).freeMint(tokenAmount);
  })

  it("Should let spender transfer tokens from owner to receiver", async () => {

    // Get signature from owner
    const signatureResult = await signERC2612Permit(
      owner.provider, 
      erc20PermitToken.address,
      owner.address,
      spender.address,
      tokenAmount.toString()
    )

    // Send permit transaction
    await erc20PermitToken.connect(relayer).permit(
      owner.address,
      spender.address,
      tokenAmount,
      signatureResult.deadline,
      signatureResult.v,
      signatureResult.r,
      signatureResult.s
    )

    // Check allowance
    expect(await erc20PermitToken.allowance(owner.address, spender.address)).to.equal(tokenAmount);

    // Transfer token
    expect(await erc20PermitToken.balanceOf(owner.address)).to.equal(tokenAmount);
    expect(await erc20PermitToken.balanceOf(receiver.address)).to.equal(0);

    await erc20PermitToken.connect(spender).transferFrom(owner.address, receiver.address, tokenAmount);

    expect(await erc20PermitToken.balanceOf(owner.address)).to.equal(0);
    expect(await erc20PermitToken.balanceOf(receiver.address)).to.equal(tokenAmount);

    // Check allowance after transfer
    expect(await erc20PermitToken.allowance(owner.address, spender.address)).to.equal(0);

  })
})