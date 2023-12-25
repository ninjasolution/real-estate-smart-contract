// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers } = require("hardhat");

const eth = (amount) => {
  return ethers.utils.parseEther(amount.toString())
}

async function main() {

  let router = "0x10ED43C718714eb63d5aA57B78B54704E256024E"; // bsc main
  // let router = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"; // goerli
  let vault = "0xD14562135758d083698b0Ae04d1F355CC35D23F9";
  let dev = "0x52098834b7b129283e12C81Be41da131477cf378";
  let deployer = "0x52098834b7b129283e12C81Be41da131477cf378";
  let usdt = "0x55d398326f99059fF775485246999027B3197955";
  let cwf = "0x07869C388A4dEcf49bDC61eC1ED2B3AF8a27f116";
  let _presale = "0x1F4F66D066Ff8D3ab31Ea470272773E312c87D59";
  let _vesting = "0x8B452F0F241d48e4c0e711ac66146Cd3d060d8B7";

  /* Tokens */
  const CWF = await hre.ethers.getContractFactory("CWF");
  // const cwfToken = await CWF.deploy(router, vault, dev)
  const cwfToken = await CWF.attach(cwf)
  console.log("CWF Token to:", cwfToken.address);

  /* Presale */
  const Presale = await hre.ethers.getContractFactory("Presale");
  // const presale = await Presale.deploy()
  const presale = await Presale.attach(_presale);
  console.log("Presale to:", presale.address);

  /* Vesting */
  const Vesting = await hre.ethers.getContractFactory("LinearVesting");
  // const vesting = await Vesting.deploy()
  const vesting = await Vesting.attach(_vesting)
  console.log("Vesting to:", vesting.address);

  let tagIds = ["Private", "Seed", "Community"]
  // let tagIds = ["Private"]
  let prices = [5000, 5500, 6000] // [0.05, 0.052, 0.054]
  let allocations = [42000000, 70000000, 140000000] //[6%, 10%, 20%]
  //12.6M
  let tags = []
  let block = await ethers.provider.getBlock("latest")
  let timestamp = block.timestamp;

  timestamp = Number.parseInt(timestamp) + 3600*24*0.01
  let grandTotal = 0;

  for (let i = 0; i < tagIds.length; i++) {
    tags.push({
      status: 0,
      price: prices[i].toString(),
      startAt: ethers.BigNumber.from(timestamp),
      endAt: ethers.BigNumber.from(timestamp + 3600 * 24*15),
      maxTagCap: eth((allocations[i] * prices[i]) / 100000),
      allocation: eth(allocations[i]),
      maxParticipants: "5000000"
    });
    grandTotal += allocations[i] * prices[i]/100000;
    timestamp += 3600 * 24;
  }
  grandTotal = grandTotal * 2;

  let presaleSetup = {
    vestingContract: vesting.address,
    paymentReceiver: vault,
    paymentToken: usdt,
    grandTotal: eth(10),
    summedMaxTagCap: eth(100),
    refundFee: 10000,
    minAllocation: ethers.utils.parseEther("1"),
    maxAllocation: ethers.utils.parseEther("10000000"),
  }

  let contractSetup = {
    admin: deployer,
    vestedToken: cwfToken.address,
    platformFee: 0,
    totalTokenOnSale: eth(210000000),
    gracePeriod: 60,
    decimals: 18
  }
  timestamp = Number.parseInt(block.timestamp) + 3600*24*30

  let vestingSetup = {
    startTime: timestamp,
    cliff: 3600 * 24 * 10,
    duration: 3600 * 24 * 30 * 6,
    initialUnlockPercent: 0 // 20%
  };

  // await presale.initialize(deployer, presaleSetup, [], []);
  // console.log( "Initialized");
  // await presale.updateGrandTotal(eth(grandTotal));
  // console.log( "updateGrandTotal");
  await presale.updateSetTags(tagIds, tags, { gasLimit: 20000000 });
  console.log( "updateSetTags");
  // await presale.updateSetTag(tagIds[0], tags[0]);
  console.log(await presale.tagIds())

  // await vesting.initializeCrowdfunding(
  //   contractSetup,
  //   vestingSetup
  // );
  // console.log("1111111")
  // await vesting.addAdmin(presale.address);
  // console.log("22222222")

  // await cwfToken.approve(vesting.address, eth(10));
  // await cwfToken.transfer(vesting.address, eth(10));
  // console.log("3333333")

  // await presale.openPresale();
  // await presale.openTag(tagIds[0]);
  // await vesting.withdraw(cwfToken.address, eth(10));
















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
  // const staking = await Staking.deploy(deployer, "CWF Staking", cwf, cwf, durations, rates);
  // await staking.deployed();
  // console.log("Staking to:", staking.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
