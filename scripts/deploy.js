// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers } = require("hardhat");

async function main() {

  let router = "0x10ED43C718714eb63d5aA57B78B54704E256024E";
  let vault = "0xe8de46e6df55dE3dDF44fd022376522812aa8A68";
  let dev = "0xa415D52dd2bf10e2406e9e75a7F411EFCf025e64";

  /* Tokens */
  const CWF = await hre.ethers.getContractFactory("CWF");
  const cwfToken = await CWF.deploy(router, vault, dev)
  console.log("Security Token to:", cwfToken.address);


  /* Yield Farming */
  const cwfTokenaddr = "0x4cA09ed88B1EfD21FC9a62A531126FA6FEcE61cB";
  const lpTokenaddr = "0x93F7A82f788A826ad099204dbf1835FD8A8B529A";


  const Farming = await ethers.getContractFactory("YieldFarming")
  const farming = await Farming.deploy(lpTokenaddr, cwfTokenaddr)
  await farming.deployed()
  console.log("Yield Farming to:", farming.address);
  await farming.resetAndsetStartEndBlock(1000, 0, 15);


  /* Staking */
  let durations = ["2592000", "5184000", "15552000", "23328000"]; //30 days, 90 days, 180 days, 270 days
  let rates = ["32", "123", "297", "518"]; // APR: 0.32%, 1.23%, 2.97%, 5.18% APY: 4%, 5%, 6%, 7%

  const Staking = await ethers.getContractFactory("Staking");
  const staking = await Staking.deploy(dev, "CWF Staking", cwfTokenaddr, cwfTokenaddr, durations, rates);
  await staking.deployed();
  console.log("Staking to:", staking.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
