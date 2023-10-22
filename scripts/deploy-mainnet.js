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

  // let router = "0x10ED43C718714eb63d5aA57B78B54704E256024E"; // bsc main
  let router = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"; // goerli
  let vault = "0xB528422D8CB691a9Ab1D85F8e42ccd14dC6E54f5";
  let dev = "0xa415D52dd2bf10e2406e9e75a7F411EFCf025e64";
  let deployer = "0x7B7887059860a1A21f3C62542B6CE5c0a23c76d5";
  let usdt = "0x55d398326f99059fF775485246999027B3197955";
  let cwf = "0x677dDBfEA0D7870A6bE880eaa4Ce0d292cECfadC";
  let _presale = "0x66751837c9F9e649d3Ce6b08cE511446FE6aFe67";
  let _vesting = "0xDF284E8483190E7A4E1D0fc5f1D2b30e7D67A5c4";

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
  let prices = [1900, 1950, 2000] // [0.19, 0.195, 0.20]
  let allocations = [20000000, 60000000, 200000000]
  let tags = []
  let block = await ethers.provider.getBlock("latest")
  let timestamp = block.timestamp;
  timestamp = Number.parseInt(timestamp) + 3600*24
  let grandTotal = 0;
  for (let i = 0; i < tagIds.length; i++) {
    tags.push({
      status: 0,
      price: prices[i].toString(),
      startAt: ethers.BigNumber.from(timestamp),
      endAt: ethers.BigNumber.from(timestamp + 3600 * 24),
      maxTagCap: eth((allocations[i] * prices[i])/100000),
      allocation: eth(allocations[i]),
      maxParticipants: "500"
    });
    grandTotal += allocations[i] * prices[i]/100000;
    timestamp += 3600 * 24;
  }

  let presaleSetup = {
    vestingContract: vesting.address,
    paymentToken: usdt,
    grandTotal: eth(grandTotal),
    summedMaxTagCap: eth(grandTotal),
    refundFee: 10000,
    minAllocation: ethers.utils.parseEther("1"),
    maxAllocation: ethers.utils.parseEther("10000000"),
  }
  let contractSetup = {
    paymentReceiver: vault,
    admin: deployer,
    vestedToken: cwf,
    platformFee: 0,
    totalTokenOnSale: eth(210000000),
    gracePeriod: 60,
    decimals: 18
  }

  let vestingSetup = {
    startTime: timestamp + 100,
    cliff: 3600 * 24 * 30,
    duration: 3600 * 24 * 30 * 5,
    initialUnlockPercent: 20000 // 20%
  };

  // console.log( tagIds, tags)
  // await presale.initialize(deployer, presaleSetup, [], []);
  await presale.updateGrandTotal(eth(grandTotal + 10000));
  console.log(timestamp)
  console.log("update grand total")
  await presale.updateSetTags(tagIds, tags);
  console.log(await presale.tagIds())

  // await vesting.initializeCrowdfunding(
  //   contractSetup,
  //   vestingSetup
  // );
  // console.log("1111111")
  // await vesting.addAdmin(presale.address);
  // console.log("22222222")

  // await cwfToken.approve(vesting.address, eth(700000));
  // await cwfToken.transfer(vesting.address, eth(70000));
  // console.log("3333333")

  // await presale.openPresale();
  // await presale.openTag(tagIds[0]);
















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
