const { expect } = require("chai");
const { ethers } = require("hardhat");
const { parseEther } = ethers;

describe("Staking Contract", function () {
  let deployer, user;
  let baseToken, govToken, staking;

  beforeEach(async function () {
    [deployer, user] = await ethers.getSigners();

    const MockERC20Factory = await ethers.getContractFactory("MockERC20");
    baseToken = await MockERC20Factory.deploy("StakeToken", "STK");
    await baseToken.waitForDeployment();
    console.log("✅ BaseToken:", await baseToken.getAddress());

    const GovTokenFactory = await ethers.getContractFactory("GovToken");
    govToken = await GovTokenFactory.deploy();
    await govToken.waitForDeployment();
    console.log("✅ GovToken:", await govToken.getAddress());

    const StakingFactory = await ethers.getContractFactory("Staking");
    staking = await StakingFactory.deploy(
      await baseToken.getAddress(),
      await govToken.getAddress()
    );
    await staking.waitForDeployment();
    console.log("✅ Staking:", await staking.getAddress());

    // Now it's safe to wire minter
    await govToken.setMinter(await staking.getAddress());
    await baseToken.transfer(user.address, parseEther("1000"));
  });

  it("should allow user to stake and accrue rewards", async function () {
    const stakeAmount = parseEther("100");
    await baseToken.connect(user).approve(await staking.getAddress(), stakeAmount);
    await staking.connect(user).stake(stakeAmount);

    await ethers.provider.send("evm_increaseTime", [86400]);
    await ethers.provider.send("evm_mine");

    await staking.connect(user).claimGovToken();
    const govBalance = await govToken.balanceOf(user.address);

    expect(govBalance).to.be.closeTo(stakeAmount);
  });

  it("should allow user to unstake and receive base tokens + rewards", async function () {
    const stakeAmount = parseEther("50");
    await baseToken.connect(user).approve(await staking.getAddress(), stakeAmount);
    await staking.connect(user).stake(stakeAmount);

    await ethers.provider.send("evm_increaseTime", [86400]);
    await ethers.provider.send("evm_mine");

    await staking.connect(user).unstake();

    const userBaseBalance = await baseToken.balanceOf(user.address);
    const userGovBalance = await govToken.balanceOf(user.address);

    expect(userBaseBalance).to.be.closeTo(parseEther("1000"), parseEther("0.01"));
    expect(userGovBalance).to.be.closeTo(stakeAmount);
  });
});
