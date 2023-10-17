const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { constants } = require("ethers");
const { ethers } = require("hardhat");
require("dotenv").config();


function eth(amount) {
  return ethers.utils.parseEther(amount.toString())
}

function day(number) {
  return 3600 * 24 * number;
}

function _token(amount) {
  return (amount * 100).toString()
}

describe("Staking", function () {

  var stakingSCName = "IDO Staking"
  // var durations = [ethers.BigNumber.from(2592000), ethers.BigNumber.from(5184000), ethers.BigNumber.from(15552000), ethers.BigNumber.from(23328000)];
  var durations = ["10", "100", "150", "200"];
  var rates = [100, 300, 700, 1100];
 

  var deployer, fund, target, securityToken, staking, utilityToken;
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deploy() {
    const [_deployer, _fund, _target] = await ethers.getSigners();

    const SecurityToken = await ethers.getContractFactory("PaymentToken")
    const _securityToken = await SecurityToken.deploy()
    await _securityToken.deployed()


    const UtilityToken = await ethers.getContractFactory("PaymentToken")
    const _utilityToken = await UtilityToken.deploy()
    await _utilityToken.deployed()

    const Staking = await ethers.getContractFactory("Staking");
    staking = await Staking.deploy(_deployer.address, stakingSCName, _securityToken.address, _utilityToken.address, durations, rates);
    await staking.deployed();

    // durations = ["2592000", "5184000", "15552000", "23328000"]; //30 days, 90 days, 180 days, 270 days
    // rates = ["32", "123", "297", "518"]; // APR: 0.32%, 1.23%, 2.97%, 5.18% APR: 4%, 5%, 6%, 7%


    // const _staking = await Staking.deploy(stakingSCName, _securityToken.address, _utilityToken.token)
    // await _staking.deployed()

    console.log(`Staking:  ${staking.address}, Deployer: ${_deployer.address}`)

    deployer = _deployer;
    fund = _fund;
    target = _target;
    securityToken = _securityToken;
    utilityToken = _utilityToken;
  }

  before(async () => {
    await deploy();
  })

  describe("Deployemnt", function () {


    it('deploys successfully', async () => {
      expect(staking.address).to.not.equals(0x0);
      expect(staking.address).to.not.equals('');
      expect(staking.address).to.not.equals(null);
      expect(staking.address).to.not.equals(undefined);
    })

    it('has a name', async () => {
      let name = await staking.name();
      expect(name).to.equals(stakingSCName);
    })

    it('has tokenAddress', async () => {

      let tokenAddr = await staking.stakeTokenAddr();
      expect(tokenAddr).to.equals(securityToken.address);

    })

    it('has rate', async () => {


      for (let i = 0; i < durations.length; i++) {
        let rateAndRation = await staking.rateAndDurations(i, 0);
        expect(rateAndRation[0]).to.equals(rates[i].toString());
        expect(rateAndRation[2]).to.equals(durations[i].toString());
      }
    })

  })

  describe('Rewards', function () {

    it('should not add 0 rewards', async () => {
      await expect(staking.addReward(0)).to.be.revertedWith("Reward must be positive")
    })

    it('should not add reward greater than allowance', async () => {
      const approval = eth(1000);
      const rewards = eth(2000);
      await utilityToken.approve(staking.address, approval);
      await expect(staking.addReward(rewards)).to.be.revertedWith("ERC20: insufficient allowance")
    })

    it('adds rewards', async () => {
      const reward = eth(10000);
      await utilityToken.approve(staking.address, reward);
      await staking.addReward(reward);
      const totalReward = await utilityToken.balanceOf(staking.address);
      expect(totalReward).to.be.equal(reward, "Total rewards is correct")
    })
  })

  describe('Setting rate, lockDuration and eligibilityAmount', function () {

    it('should set rate and lock duration by owner', async () => {

      durations.push(ethers.BigNumber.from(30 * 24 * 3600))
      rates.push(1200)
      await staking.addRateAndDuration(rates[rates.length - 1], durations[durations.length - 1]);
      let rateAndRation = await staking.rateAndDurations(rates.length - 1, 0);
      expect(rateAndRation[0]).to.be.equal(rates[rates.length - 1], "Rate set successfully by owner");
      expect(rateAndRation[2]).to.be.equal(durations[durations.length - 1], "Lock set successfully");
    })

    it('should not allow others to set rate and lock duration', async () => {
      rates[1] = 400
      await expect(staking.connect(fund).setRate(1, 400)).to.be.revertedWith("Ownable: caller is not the owner")
    })
  })

  describe('Staking', function () {

    it('should not stake 0 amount', async () => {
      await expect(staking.stake(0, 0)).to.be.revertedWith("Can't stake 0 amount")
    })

    it('should not add greater than allowance', async () => {
      const approval = eth(4000);
      const stake = eth(5000);
      await securityToken.approve(staking.address, approval);
      await expect(staking.stake(0, stake)).to.be.revertedWith("Make sure to add enough allowance")
    })

    it('adds stakes', async () => {
      const stake = eth(2000);
      await securityToken.approve(staking.address, stake);
      await staking.stake(0, stake);
      const deposits = await staking.deposits(0, deployer.address);
      await expect(deposits[0]).to.be.equal(eth(2000), "Staked correctly");
      await expect(deposits[3]).to.be.equal(0, "Index is set correctly");
      await expect(deposits[5]).to.be.equal(false, "Staked correctly");
      const stakedBalance = await staking.stakedBalance();
      await expect(stakedBalance).to.be.equal(eth(2000), "Staked Balance is correct");
      const stakedTotal = await staking.stakedTotal();
      await expect(stakedTotal).to.be.equal(eth(2000), "Staked total is correct");
    })

    it('should allow multiple stakes from same user and reset the lock', async () => {

      const stake = eth(1000);
      await securityToken.approve(staking.address, stake);
      function timeout(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
      }
      await timeout(2000);
      await staking.stake(0, stake);
      const deposits = await staking.deposits(0, deployer.address);
      await expect(deposits[0]).to.be.equal(eth(3000), "Staked correctly");
      await expect(deposits[5]).to.be.equal(false, "Not paid yet");
      await expect(deposits[4]).to.be.equal(eth(3000 * (rates[0]/10000) * 2 /durations[0]), "Updated"); // 2 seconds of 5 seconds


    })

    it('should stake according to the changes in rates', async () => {

      const stake0 = eth(2000);
      await securityToken.approve(staking.address, stake0);
      await staking.stake(0, stake0);

      const historyIndex = await staking.index(0);
      const rateAndDuration = await staking.rateAndDurations(0, historyIndex);

      await expect(rateAndDuration[0]).to.be.equal(rates[0], "Rates are synced1");

      rates[0] = 150; //update current rate
      await staking.setRate(0, 150);
      const stake = eth(2000);
      await securityToken.transfer(fund.address, stake);
      await securityToken.connect(fund).approve(staking.address, stake);
      await staking.connect(fund).stake(0, stake);
      const userRate1 = await staking.rateAndDurations(0, 1);
      await expect(userRate1[0]).to.be.equal(rates[0], "Rates are synced2");
    })
  })

  describe('Withdraw', function () {

    it('should not allow to withdraw without stakes', async () => {
      await expect(staking.connect(target).withdraw(0)).to.be.revertedWith("No stakes found for user")
    })

    it('should not allow withdraw before deposit time', async () => {
      await expect(staking.withdraw(0)).to.be.revertedWith("Requesting before lock time")
    })


    // it('withdraws successfully', async () => {

    //   const stakedBalance = await staking.stakedBalance();
    //   const rewardBalance = await staking.rewardBalance();
    //   const amount = await staking.deposits(0, fund.address);
    //   const depositAmount = amount[0];
    //   function timeout(ms) {
    //     return new Promise(resolve => setTimeout(resolve, ms));
    //   }
    //   await timeout(11000);
    //   await staking.connect(fund).withdraw(0);
    //   const balance1 = await securityToken.balanceOf(fund.address);
    //   // console.log(balance1.toString());
    //   const latestStakedBalance = await staking.stakedBalance();
    //   await expect(latestStakedBalance).to.be.equal(stakedBalance.sub(depositAmount), "Staked balance updated correctly");

    //   const reward = balance1.sub(ethers.BigNumber.from(depositAmount));
    //   // console.log(reward.toString());
    //   const latestRewardBalance = await staking.rewardBalance();
    //   await expect(latestRewardBalance).to.be.equal(rewardBalance.sub(reward), "Reward Balance updated correctly");
    // })

    it('should not withdraw twice', async () => {
      let timestamp = await time.latest();

      await time.increaseTo(timestamp + 1000);
      await staking.withdraw(0);
      await expect(staking.withdraw(0)).to.be.revertedWith("No stakes found for user")
    })
  })

 
  


});
