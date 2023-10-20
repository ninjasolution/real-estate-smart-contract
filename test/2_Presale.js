const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { UniswapV2Deployer, ethers } = require("hardhat");

require("dotenv").config();

function eth(amount) {
  return ethers.utils.parseEther(amount.toString())
}


describe("Presale", function () {

  var deployer, fund, target, cwfToken, paymentToken, cwfVesting, cwfFactory;
  var presale, vesting;
  var presaleSetup, contractSetup, vestingSetup;

  var tagIdentifiers = ["Private", "Seed", "Community"]
  var tags = [];

  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deploy() {
    [deployer, fund, target] = await ethers.getSigners();
    const { factory, router, weth9 } = await UniswapV2Deployer.deploy(deployer);

    const PaymentToken = await ethers.getContractFactory("PaymentToken")
    paymentToken = await PaymentToken.deploy()
    await paymentToken.deployed()

    const CWFToken = await ethers.getContractFactory("CWF")
    cwfToken = await CWFToken.deploy(router.address, fund.address, target.address)
    await cwfToken.deployed()

    const Presale = await ethers.getContractFactory("Presale")
    presale = await Presale.deploy()
    await presale.deployed()

    const Vesting = await ethers.getContractFactory("LinearVesting")
    vesting = await Vesting.deploy()
    await vesting.deployed()

    presaleSetup = {
      vestingContract: vesting.address,
      paymentToken: paymentToken.address,
      grandTotal: eth(100),
      summedMaxTagCap: eth(1000),
      refundFee: 10000,
      minAllocation: ethers.utils.parseEther("1"),
      maxAllocation: ethers.utils.parseEther("100000"),
    }

    contractSetup = {
      paymentReceiver: deployer.address,
      admin: deployer.address,
      vestedToken: cwfToken.address,
      platformFee: 10,
      totalTokenOnSale: eth(100),
      gracePeriod: 60,
      decimals: 18
    }
    let timestamp = await time.latest();

    vestingSetup = {
      startTime: timestamp + 1,
      cliff: 10,
      duration: 50,
      initialUnlockPercent: 1000 // 1%
    };


    let tagIds = []

    let tags = []

    await presale.initialize(deployer.address, presaleSetup, tagIds, tags);
    await vesting.initializeCrowdfunding(
      contractSetup,
      vestingSetup
    );
    await vesting.transferOwnership(presale.address);

    await cwfToken.approve(vesting.address, eth(10000));
    await cwfToken.transfer(vesting.address, eth(10000));


  }

  before(async () => {
    await deploy();

    let lastStart = 60;
    let lastEnd = 3600 * 10;
    let maxTagAllocation = eth(1_000_000);
    tags = [];

    for (let i = 0; i < tagIdentifiers.length; i++) {
      maxTagAllocation = ethers.utils.parseEther((1000000 * (i || 0 + 1)).toString());

      let _now = await time.latest();
      tags.push(
        {
          status: 0,
          presaleTokenPerPaymentToken: 10,
          startAt: _now + lastStart,
          endAt: _now + lastEnd,
          maxTagCap: eth(200000),
          allocation: ethers.utils.parseEther("23000000"),
          maxParticipants: 500000
        }
      );

      lastStart = lastEnd;
      lastEnd += 3600;
    }

  })



  describe("Setup", function () {


    it('Setup', async () => {
      let summedMaxTagCap_ = 0;
      for (let i = 0; i < tags.length; ++i) {
        summedMaxTagCap_ += tags[i].maxTagCap;
      }

      await presale.updateGrandTotal(eth(50000000));
      await presale.updateSetTags(tagIdentifiers, tags);
      console.log(await presale.tag(tagIdentifiers[0]))

      let setupResult = await presale.setUp();
      expect(summedMaxTagCap_.toString()).to.not.equals(setupResult.summedMaxTagCap.toString());
    })

    it('Reserve Allocation', async () => {

      let amount = ethers.utils.parseEther("1000");
      let refundAmount = ethers.utils.parseEther("900");

      await presale.openPresale();
      await presale.openTag(tagIdentifiers[0]);

      await paymentToken.approve(presale.address, amount)
      await presale.reserveAllocation(tagIdentifiers[0], amount)

      await cwfToken.addWhitelist(vesting.address);
      // console.log(ethers.utils.formatEther(await vesting.computeReleasableAmount(allocations[0].tagId, deployer.address)))
      await vesting.refund(tagIdentifiers[0], refundAmount)
      await vesting.claim(tagIdentifiers[0])

    })

  })




});
