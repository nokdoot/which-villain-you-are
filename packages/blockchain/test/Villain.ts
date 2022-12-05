import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { Villain } from "../typechain-types";

describe("Pausable", () => {

  let villainNft: Villain;
  let [owner, user1, user2]: SignerWithAddress[] = [];

  beforeEach(async () => {
    const Villain = await ethers.getContractFactory("Villain");
    villainNft = await Villain.deploy('V', 'V', 'V', 20);
    
    [owner, user1, user2] = await ethers.getSigners();
  });

  it("Pausable", async () => {
    const mintTx = await villainNft.connect(user1).mint(1, { value: ethers.utils.parseEther('500') });
    await mintTx.wait();

    const pauseTx = await villainNft.pause();
    await pauseTx.wait();

    const transferTx = villainNft.connect(user1)["safeTransferFrom(address,address,uint256)"](user1.address, user2.address, 0);
    await expect(transferTx).to.be.revertedWith("ERC721Pausable: token transfer while paused");
  });

  it("PausableEach", async () => {
    const mint1Tx = await villainNft.connect(user1).mint(1, { value: ethers.utils.parseEther('500') });
    await mint1Tx.wait();

    const mint2Tx = await villainNft.connect(user2).mint(1, { value: ethers.utils.parseEther('500') });
    await mint2Tx.wait();

    const pause1Tx = await villainNft.pauseToken(0);
    await pause1Tx.wait();

    const transfer1Tx = villainNft.connect(user1)["safeTransferFrom(address,address,uint256)"](user1.address, user2.address, 0);
    await expect(transfer1Tx).to.be.revertedWith("ERC721PausableEach: token transfer while paused");

    const transfer2Tx = await villainNft.connect(user2)["safeTransferFrom(address,address,uint256)"](user2.address, user1.address, 1);
    await transfer2Tx.wait();

    const transfer3Tx = await villainNft.connect(user1)["safeTransferFrom(address,address,uint256)"](user1.address, user2.address, 1);
    await transfer3Tx.wait();

    const pause2Tx = await villainNft.pauseToken(1);
    await pause2Tx.wait();

    const transfer4Tx = villainNft.connect(user2)["safeTransferFrom(address,address,uint256)"](user2.address, user1.address, 1);
    await expect(transfer4Tx).to.be.revertedWith("ERC721PausableEach: token transfer while paused");
  });
});
