const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { constants } = require("ethers");
const { UniswapV2Deployer, ethers } = require("hardhat");
// const { AllowanceTransfer, PERMIT2_ADDRESS, MaxAllowanceTransferAmount, AllowanceProvider, SignatureTransfer } = require("@uniswap/Permit2-sdk")
const { MerkleTree } = require('merkletreejs');

require("dotenv").config();

function eth(amount) {
  return ethers.utils.parseEther(amount.toString())
}


describe("Presale", function () {

  var deployer, fund, target, cwfToken, paymentToken, cwfVesting, cwfFactory;
  var presale, vesting;
  var presaleSetup, contractSetup, vestingSetup;

  var tagIdentifiers = ["all members", "second members", "vpr-premium2", "cwf-phase1"];
  var tags = [];
  var allocations = [];

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
    presale = await Presale.deploy(deployer.address)
    await presale.deployed()

    const Vesting = await ethers.getContractFactory("LinearVesting")
    vesting = await Vesting.deploy(deployer.address, "CWF Vesting")
    await vesting.deployed()

    presaleSetup = {
      vestingContract: vesting.address,
      paymentToken: paymentToken.address,
      grandTotal: eth(100),
      summedMaxTagCap: eth(1000),
      refundFeeDecimals: 4
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

    let name = "test-00";

    let tagIds = []

    let tags = []
    // tags.push({
    //   status: 0,
    //   startAt: ethers.BigNumber.from(timestamp + 3600),
    //   endAt: ethers.BigNumber.from(timestamp + 3600 + 3600 * 24),
    //   maxTagCap: eth(100000)
    // });

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
    let lastEnd = 3600;
    let maxTagAllocation = eth(1_000_000);
    tags = [];

    for (let i = 0; i < tagIdentifiers.length; i++) {
      maxTagAllocation = ethers.utils.parseEther((1000000 * (i + 1)).toString());

      let _now = await time.latest();
      tags.push(
        {
          status: 0,
          startAt: _now + lastStart,
          endAt: _now + lastEnd,
          maxTagCap: maxTagAllocation,
          minAllocation: ethers.utils.parseEther("100"),
          maxAllocation: ethers.utils.parseEther("100000"),
          allocation: ethers.utils.parseEther("1000000"),
          maxParticipants: 18
        }
      );

      lastStart = lastEnd;
      lastEnd += 3600;
    }


    for (let i = 0; i < 10; i++) {
      allocations.push({
        tagId: tagIdentifiers[i % tagIdentifiers.length],
        account: deployer.address,
        // maximum amount the user can spend, expressed in CWFStruct.SetUp.paymentToken
        maxAllocation: eth("10000"),
        // take CWFStorage.CWFStruct.SetUp.refundFeeDecimals into account
        refundFee: ethers.BigNumber.from("30"), // 30%, refund fee
        // price per token of the project behind the CWF, expressed in
        // `CWFSTorage.SetUp.paymentToken` (any ERC20)
        presaleTokenPerPaymentToken: ethers.BigNumber.from("12")
      })
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

      let setupResult = await presale.setUp();
      expect(summedMaxTagCap_.toString()).to.not.equals(setupResult.summedMaxTagCap.toString());
      // expect(setupResult.refundFeeDecimals).to.not.equals(contractSetup.decimals);
    })

    it('Reserve Allocation', async () => {

      let amount = ethers.utils.parseEther("1000");

      await presale.openPresale();
      await presale.openTag(allocations[0].tagId);

      await paymentToken.approve(presale.address, amount)
      await presale.reserveAllocation(amount, allocations[0])

      await cwfToken.addWhitelist(vesting.address);
      // console.log(ethers.utils.formatEther(await vesting.computeReleasableAmount(allocations[0].tagId, deployer.address)))
      await vesting.claim(allocations[0].tagId)

    })

  })




});
