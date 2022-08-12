import { ethers } from "hardhat";
import { expect } from "chai";
import { ERC721Drop } from "typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("ERC721Drop delayed reveal test", function() {

    let erc721Drop: ERC721Drop;
    let signer: SignerWithAddress;

    before(async () => {
        [signer] = await ethers.getSigners();
        erc721Drop = await ethers.getContractFactory("ERC721Drop").then(f => f.connect(signer).deploy(
            "name",
            "symbol",
            ethers.constants.AddressZero,
            0,
            ethers.constants.AddressZero
        ));
    })

    it("Should let you lazy mint regular NFTs.", async () => {
        const data = ethers.utils.solidityPack(
            ["bytes", "bytes32"],
            [ethers.utils.toUtf8Bytes(""), ethers.utils.formatBytes32String("")],
          );
        // await expect(erc721Drop.connect(signer).lazyMint(100, "baseURI", data)).to.not.be.reverted;
        await expect(erc721Drop.connect(signer).lazyMint(100, "baseURI", ethers.utils.toUtf8Bytes(""))).to.not.be.reverted;
    })
})