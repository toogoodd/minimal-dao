const { expect } = require("chai");
const { ethers } = require("hardhat");
const { parseEther } = ethers;

describe("DAO Contract", function () {
  let deployer, user;
  let govToken, dao;

  beforeEach(async function () {
    [deployer, user] = await ethers.getSigners();

    // Deploy GovToken
    const GovTokenFactory = await ethers.getContractFactory("GovToken");
    govToken = await GovTokenFactory.deploy();
    await govToken.waitForDeployment();

    // Mint tokens to user
    await govToken.setMinter(deployer.address);
    await govToken.mint(user.address, parseEther("100"));

    // Deploy DAO
    const DAOFactory = await ethers.getContractFactory("DAO");
    dao = await DAOFactory.deploy(await govToken.getAddress());
    await dao.waitForDeployment();
  });

  it("should allow creating a proposal", async function () {
    await dao.connect(user).createProposal("Proposal 1");

    const proposal = await dao.proposals(0);
    expect(proposal.description).to.equal("Proposal 1");
  });

  it("should allow voting on a proposal", async function () {
    await dao.connect(user).createProposal("Proposal 2");
    await dao.connect(user).vote(0, true);

    const proposal = await dao.proposals(0);
    expect(proposal.yesCount).to.equal(parseEther("100"));
  });

  it("should report proposal status after deadline", async function () {
    await dao.connect(user).createProposal("Proposal 3");
    await dao.connect(user).vote(0, true);

    // Fast-forward time
    await ethers.provider.send("evm_increaseTime", [3601]); // > 1 hour
    await ethers.provider.send("evm_mine");

    const status = await dao.getProposalStatus(0);
    expect(status).to.equal("Passed");
  });
});

