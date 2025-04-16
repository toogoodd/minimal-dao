// scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with:", deployer.address);

  // 1. Deploy Mock Base Token (DAI-like)
  const BaseToken = await ethers.getContractFactory("MockERC20");
  const baseToken = await BaseToken.deploy("StakeToken", "STK");
  await baseToken.deployed();
  console.log("BaseToken deployed to:", baseToken.address);

  // 2. Deploy GovToken
  const GovToken = await ethers.getContractFactory("GovToken");
  const govToken = await GovToken.deploy();
  await govToken.deployed();
  console.log("GovToken deployed to:", govToken.address);

  // 3. Deploy Staking Contract
  const Staking = await ethers.getContractFactory("Staking");
  const staking = await Staking.deploy(baseToken.address, govToken.address);
  await staking.deployed();
  console.log("Staking deployed to:", staking.address);

  // 4. Set Staking contract as minter
  await govToken.setMinter(staking.address);
  console.log("Staking contract set as GovToken minter");

  // 5. Deploy DAO
  const DAO = await ethers.getContractFactory("DAO");
  const dao = await DAO.deploy(govToken.address);
  await dao.deployed();
  console.log("DAO deployed to:", dao.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
