// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers } = require("hardhat");

async function main() {

  let router = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  let vault = "0x7B7887059860a1A21f3C62542B6CE5c0a23c76d5";
  let permit2 = "0xD1f6475BDD6b159323e441D2E09bC2e4E82bC031";
  let presaleDeployer = "0xbaD4af6E079f94a4b6D36828685BcB2A86Ace1b1";


  /* Presale Deployer */
  // const PresaleDeployer = await hre.ethers.getContractFactory("PresaleDeployer");
  // const presaleDeployer = await PresaleDeployer.deploy()
  // console.log("PresaleDeployer deployed to:", presaleDeployer.address);






  /* Presale Factory */
  // const PresaleFactory = await hre.ethers.getContractFactory("PresaleFactory");
  // const presaleFactory = await PresaleFactory.deploy(presaleDeployer)
  // const presaleFactory = await PresaleFactory.attach("0xa0689fFC474893456702Ef45DDb9762AC005410C");
  // console.log("PresaleFactory deployed to:", presaleFactory.address);

 



  /* Permit2 */
  // const Permit2 = await hre.ethers.getContractFactory("Permit2");
  // const permit2 = await Permit2.deploy()
  // console.log("Permit2 deployed to:", permit2.address);





  /* Presale */
  // const Presale = await hre.ethers.getContractFactory("Presale");
  // const presale = await Presale.deploy(vault)
  // console.log("Presale deployed to:", presale.address);





  /* Presale Vesting */
  // const LinearVesting = await hre.ethers.getContractFactory("LinearVesting");
  // const linearVesting = await LinearVesting.deploy("0x7B7887059860a1A21f3C62542B6CE5c0a23c76d5", "Presale Vesting")
  // console.log("LinearVesting deployed to:", linearVesting.address);







  /* Tokens */
  // const AUDCT = await hre.ethers.getContractFactory("Token");
  // const stToken = await AUDCT.deploy("Australian Decentralised Capital Token", "AUDCT", 1000000000)
  // console.log("Security Token to:", stToken.address);

  // const ITR = await hre.ethers.getContractFactory("Token");
  // const utToken = await ITR.deploy("Interest Tax Rent", "ITR", 1000000000)
  // console.log("Utility Token to:", utToken.address);


  // const Token = await hre.ethers.getContractFactory("Token");
  // const token = await Token.deploy("Security Token", "ST", 1000000000)
  // console.log("Token to:", token.address);

  // await hre.run("verify:verify", {
  //   address: token.address,
  //   constructorArguments: ["Security Token", "ST", 10000000]
  // });



  /* Yield Farming */
  const securityTokenaddr = "0x4cA09ed88B1EfD21FC9a62A531126FA6FEcE61cB";
  const lpTokenaddr = "0x93F7A82f788A826ad099204dbf1835FD8A8B529A";
  const utilityTokenAddr = "0x5De688978BC3550032424264158a301A65B23F16";
  const farmingAddr = "0x246Bf9832ec5184A1A0c8dab6F580BABD2B6eC34";


  // const Farming = await hre.ethers.getContractFactory("YieldFarming");
  // // const farming = await Farming.deploy(lpTokenaddr, utilityTokenAddr)
  // // console.log("Yield Farming deployed to:", farming.address);
  // const farming = await Farming.attach(farmingAddr)

  // let curBlock = await farming.currentBlock();
  // curBlock = Number.parseInt(curBlock);
  // let rewardAmount = ethers.utils.parseEther("1000");
  // // let duration = 20 * 60 * 24 * 365 // year
  // let duration = 3600 * 24 * 30 // year
  // let startBlock = curBlock + 10;
  // let RewardToken = await hre.ethers.getContractFactory("Token");
  // let rewardToken = RewardToken.attach(utilityTokenAddr);
  // console.log(await rewardToken.balanceOf("0x7B7887059860a1A21f3C62542B6CE5c0a23c76d5"));

  // await rewardToken.approve(farming.address, rewardAmount);
  // await farming.resetAndsetStartEndBlock(rewardAmount, startBlock, startBlock + duration);




  /* Funding Token */
  // let curBlock = await ethers.provider.getBlock("latest");
  // let timestamp = curBlock.timestamp;
  // const Funding = await ethers.getContractFactory("FundingToken")
  // const _funding = await Funding.deploy("Funding Presale Token", ethers.utils.parseEther("10000000"), timestamp + 25, timestamp + 10000, "0x7B7887059860a1A21f3C62542B6CE5c0a23c76d5", securityTokenaddr)
  // await _funding.deployed()
  // console.log("Funding deployed to:", _funding.address);

  // const FundingFactory = await ethers.getContractFactory("FundingFactory")
  // const _fundingFactory = await FundingFactory.deploy()
  // await _fundingFactory.deployed()
  // console.log("Funding Factory deployed to:", _fundingFactory.address);






  /* Staking */
  const StakingFactory = await ethers.getContractFactory("StakingFactory")
  const _stakingFactory = await StakingFactory.deploy()
  await _stakingFactory.deployed()
  console.log("Staking Factory deployed to:", _stakingFactory.address);

  // const _stakingFactory = StakingFactory.attach("0xd268DF015E770484670492f91AB5DBFeE9a7fb77")



  let durations = ["2592000", "5184000", "15552000", "23328000"]; //30 days, 90 days, 180 days, 270 days
  let rates = ["32", "123", "297", "518"]; // APR: 0.32%, 1.23%, 2.97%, 5.18% APY: 4%, 5%, 6%, 7%

  let stakingArgs = {
    owner: vault,
    name: "AUDCT Staking",
    stakeToken: securityTokenaddr,
    rewardToken: utilityTokenAddr,
    durations,
    rates
  }

  let factoryTx = await _stakingFactory.createStaking(stakingArgs);
  const factoryReceipt = await factoryTx.wait();

  const event = factoryReceipt.events[2];
  console.log("Staking deployed to:", event.args[2]);


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
