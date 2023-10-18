// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers } = require("hardhat");

function eth(amount) {
  return ethers.utils.parseEther(amount.toString())
}

async function main() {

  // let router = "0x10ED43C718714eb63d5aA57B78B54704E256024E"; // bsc main
  let router = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"; // bsc main
  let vault = "0xe8de46e6df55dE3dDF44fd022376522812aa8A68";
  let dev = "0xa415D52dd2bf10e2406e9e75a7F411EFCf025e64";
  let deployer = "0x7B7887059860a1A21f3C62542B6CE5c0a23c76d5";
  let usdt = "0x7E887A370A403fdAbeAaE18875317731FBf9D73b";
  let cwf = "0xd60B6A76c532E51E44c8CA3e42672E2a73b6B1bb";
  let _vesting = "0x142230Fcf0E245FceA810aafa1f06F12D5c7cA3f";
  let _presale = " 0x852Ea2423de04B04E6e2702618463752E2c800ca";

  /* Tokens */
  const CWF = await hre.ethers.getContractFactory("CWF");
  const cwfToken = await CWF.deploy(router, vault, dev)
  // const cwfToken = await CWF.attach(cwf)
  console.log("CWF Token to:", cwfToken.address);

  /* Presale */
  // const Presale = await hre.ethers.getContractFactory("Presale");
  // const presale = await Presale.deploy(deployer)
  // // const presale = await Presale.attach(_presale);
  // console.log("Presale to:", presale.address);

  // /* Vesting */
  // const Vesting = await hre.ethers.getContractFactory("LinearVesting");
  // const vesting = await Vesting.deploy(deployer, "CWF Vesting")
  // // const vesting = await Vesting.attach(_vesting)
  // console.log("Vesting to:", vesting.address);


  // let presaleSetup = {
  //   vestingContract: vesting.address,
  //   paymentToken: usdt,
  //   grandTotal: eth(34000000),
  //   summedMaxTagCap: eth(17000000),
  //   refundFeeDecimals: ethers.BigNumber.from(200)
  // }

  // let contractSetup = {
  //   paymentReceiver: vault,
  //   admin: deployer,
  //   vestedToken: cwf,
  //   platformFee: 10,
  //   totalTokenOnSale: eth(70000000),
  //   gracePeriod: 60,
  //   decimals: 18
  // }
  // let block = await ethers.provider.getBlock("latest")
  // let timestamp = block.timestamp;

  // let vestingSetup = {
  //   startTime: timestamp + 100,
  //   cliff: 3600 * 24 * 30,
  //   duration: 3600 * 24 * 30 * 5,
  //   initialUnlockPercent: 20000 // 20%
  // };

  // let tagIds = ["Presale"]

  // let tags = []
  // tags.push({
  //   status: 0,
  //   startAt: ethers.BigNumber.from(timestamp + 3600),
  //   endAt: ethers.BigNumber.from(timestamp + 3600 + 3600 * 24),
  //   maxTagCap: eth(10000000),
  //   minAllocation: ethers.utils.parseEther("100"),
  //   maxAllocation: ethers.utils.parseEther("100000"),
  //   allocation: ethers.utils.parseEther("1000000"),
  //   maxParticipants: 18
  // });

  // await presale.initialize(deployer, presaleSetup, tagIds, tags);
  // console.log("00000")
  // await vesting.initializeCrowdfunding(
  //   contractSetup,
  //   vestingSetup
  // );
  // console.log("1111111")
  // await vesting.transferOwnership(presale.address);
  // console.log("22222222")

  // await cwfToken.approve(vesting.address, eth(700000));
  // await cwfToken.transfer(vesting.address, eth(70000));
  // console.log("3333333")



  /* Yield Farming */
  // const lpTokenaddr = "0x93F7A82f788A826ad099204dbf1835FD8A8B529A";


  // const Farming = await ethers.getContractFactory("YieldFarming")
  // const farming = await Farming.deploy(lpTokenaddr, cwf)
  // await farming.deployed()
  // console.log("Yield Farming to:", farming.address);
  // await farming.resetAndsetStartEndBlock(1000, 0, 15);


  /* Staking */
  // let durations = ["2592000", "5184000", "15552000", "23328000"]; //30 days, 90 days, 180 days, 270 days
  // let rates = ["32", "123", "297", "518"]; // APR: 0.32%, 1.23%, 2.97%, 5.18% APY: 4%, 5%, 6%, 7%

  // const Staking = await ethers.getContractFactory("Staking");
  // const staking = await Staking.deploy(dev, "CWF Staking", cwf, cwf, durations, rates);
  // await staking.deployed();
  // console.log("Staking to:", staking.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
