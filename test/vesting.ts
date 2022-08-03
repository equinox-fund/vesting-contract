import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import dayjs from "dayjs";
import { expect } from "chai";

describe("Test Vesting.sol", function () {
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addr3: SignerWithAddress;

  let vestingContract: Contract;
  let tokenContract: Contract;

  const now = dayjs().unix();
  const dayInSeconds = 86400;

  // duration: 3 month
  const duration = 90 * dayInSeconds;
  // release : daily
  const slicePeriodSeconds = 1 * dayInSeconds;
  const start = now;

  before(async () => {
    const SampleERC20Factory = await ethers.getContractFactory("SampleERC20");

    [owner, addr1, addr2, addr3] = await ethers.getSigners();

    tokenContract = await SampleERC20Factory.deploy();
  });

  describe("Vesting", () => {
    it("Should deploy contract", async () => {
      const MockVestingFactory = await ethers.getContractFactory("Vesting");
      vestingContract = await MockVestingFactory.deploy(
        tokenContract.address,
        start,
        duration,
        slicePeriodSeconds
      );

      expect(await vestingContract.start()).to.equal(start);
      expect(await vestingContract.tokenContractAddress()).to.equal(
        tokenContract.address
      );
      expect(await vestingContract.duration()).to.equal(duration);
      expect(await vestingContract.slicePeriodSeconds()).to.equal(
        slicePeriodSeconds
      );
    });

    describe("Pausing", () => {
      it("vesting should be active", async () => {
        expect(await vestingContract.isPaused()).to.equal(false);
      });

      it("should be able to pause vesting", async () => {
        await vestingContract.connect(owner).pauseVesting();
        expect(await vestingContract.isPaused()).to.equal(true);
      });

      it("Should not be able to release tokens", async function () {
        const releasing = vestingContract.connect(addr1).release(1);
        await expect(releasing).to.be.revertedWith("Vesting paused");
      });

      it("should be able to unpause vesting", async () => {
        await vestingContract.connect(owner).unpauseVesting();
        expect(await vestingContract.isPaused()).to.equal(false);
      });
    });

    /**
     * Vesting entries
     */

    describe("Vesting entries", () => {
      it("should revert adding multiple vesting entries", async () => {
        const adding = vestingContract.addMultipleVestingEntry(
          [addr1.address, addr2.address],
          [100, 200, 300]
        );

        await expect(adding).to.be.revertedWith("Arguments length mismatch");
      });

      it("Should not be able to revoke vesting entry because no vesting associated", async function () {
        const revoking = vestingContract
          .connect(owner)
          .revokeVestingEntry(addr3.address);

        await expect(revoking).to.be.revertedWith("vesting entry not found");
      });

      it("Should add multiple vesting entries", async function () {
        await vestingContract.addMultipleVestingEntry(
          [addr1.address, addr2.address, addr3.address],
          [100, 200, 200]
        );

        // check vesting entries
        expect(await vestingContract.tokensVested(addr1.address)).to.equal(100);
        expect(await vestingContract.tokensVested(addr2.address)).to.equal(200);
      });

      it("should top-up vested tokens amount", async () => {
        await vestingContract.addVestingEntry(addr1.address, 100);
        expect(await vestingContract.tokensVested(addr1.address)).to.equal(200);
      });

      it("Should be able to revoke vesting entry", async function () {
        await vestingContract.connect(owner).revokeVestingEntry(addr3.address);

        expect(await vestingContract.tokensVested(addr3.address)).to.equal(0);
      });
    });

    /**
     * Releases
     */

    describe("Releases", () => {
      it("Should not be able to release tokens (no vesting)", async function () {
        const releasing = vestingContract.connect(addr3).release(100);
        await expect(releasing).to.be.revertedWith("No vesting entry");
      });

      it("Should be able to release half according to compute function", async function () {
        // send 1000 tokens to vesting contract
        await tokenContract.mintToWallet(vestingContract.address, 1000);

        // move to 45 days in the future (half the vesting)
        // await vestingContract.setCurrentTime(start + 45 * dayInSeconds);

        await ethers.provider.send("evm_increaseTime", [45 * dayInSeconds]);
        await ethers.provider.send("evm_mine", []);

        const releasableAmount = await vestingContract.computeReleasableAmount(
          addr1.address
        );

        // we are expecting to receive 100 here
        // the addr1 got 200 vested tokens for 90 days
        // we decided to move to 45 days in the future, so he should receive half
        expect(releasableAmount).to.be.equals(100);

        const vestingEntry = await vestingContract.getVestingEntry(
          addr1.address
        );
        expect(vestingEntry.vested).to.equal(200);
        expect(vestingEntry.released).to.equal(0);
        expect(vestingEntry.releasable).to.equal(100);
      });

      it("should be able to release half and receive tokens", async () => {
        await expect(vestingContract.connect(addr1).release(100))
          .to.emit(vestingContract, "Released")
          .withArgs(addr1.address, 100);
      });

      it("should be able read vesting entries with correct data", async () => {
        const vestingEntry = await vestingContract.getVestingEntry(
          addr1.address
        );

        expect(vestingEntry.vested).to.equal(200);
        expect(vestingEntry.released).to.equal(100);
        expect(vestingEntry.releasable).to.equal(0);
      });

      it("should be able to release full tokens because vesting is done", async () => {
        // move to 90 days in the future (end the vesting)
        // await vestingContract.setCurrentTime(start + 90 * dayInSeconds);
        await ethers.provider.send("evm_increaseTime", [90 * dayInSeconds]);
        await ethers.provider.send("evm_mine", []);

        // the user 2 should be able to release all because the vesting is now finish
        await expect(vestingContract.connect(addr2).release(200))
          .to.emit(vestingContract, "Released")
          .withArgs(addr2.address, 200);
      });
    });

    /*
     * Vault
     */

    describe("Vault", () => {
      it("should be able to withdraw overflow tokens", async () => {
        // overflow is 600 because 400 tokens have been reserved for users
        const overflow = 600;
        await expect(vestingContract.connect(owner).withdrawOverflowTokens())
          .to.emit(tokenContract, "Transfer")
          .withArgs(vestingContract.address, owner.address, overflow);
      });

      it("should not be able to withdraw overflow tokens because empty", async () => {
        const withdraw = vestingContract
          .connect(owner)
          .withdrawOverflowTokens();

        await expect(withdraw).to.be.revertedWith("no overflow tokens");
      });

      it("should be able to withdraw all tokens", async () => {
        // we have 100 tokens left because there is user that release only half
        const balance = 100;

        await expect(vestingContract.connect(owner).withdrawAllTokens())
          .to.emit(tokenContract, "Transfer")
          .withArgs(vestingContract.address, owner.address, balance);
      });
    });
  });
});
