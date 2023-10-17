const { mineUpTo } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { constants } = require("ethers");
const { ethers } = require("hardhat");
require("dotenv").config();

function eth(amount) {
  return ethers.utils.parseEther(amount.toString())
}


describe("Yield Farming", function () {

  var FarmingSCName = "Yield Farming"
  // var _durations = [ethers.BigNumber.from(2592000), ethers.BigNumber.from(5184000), ethers.BigNumber.from(15552000), ethers.BigNumber.from(23328000)];
  var _durations = [ethers.BigNumber.from(10), ethers.BigNumber.from(100), ethers.BigNumber.from(150), ethers.BigNumber.from(200)];
  var _rates = [100, 300, 700, 1100];

  var deployer, fund, target, rewardToken, lpToken, farming;
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deploy() {
    const [_deployer, _fund, _target] = await ethers.getSigners();

    const LPToken = await ethers.getContractFactory("PaymentToken")
    const _lpToken = await LPToken.deploy()
    await _lpToken.deployed()

    const RewardToken = await ethers.getContractFactory("PaymentToken")
    const _rewardToken = await RewardToken.deploy()
    await _rewardToken.deployed()

    const Farming = await ethers.getContractFactory("YieldFarming")
    const _farming = await Farming.deploy(_lpToken.address, _rewardToken.address)
    await _farming.deployed()

    deployer = _deployer;
    fund = _fund;
    target = _target;
    lpToken = _lpToken;
    rewardToken = _rewardToken;;
    farming = _farming;;
  }

  before(async () => {
    await deploy();
  })

  describe("Deployemnt", function () {


    it('deploys successfully', async () => {
      expect(farming.address).to.not.equals(0x0);
      expect(farming.address).to.not.equals('');
      expect(farming.address).to.not.equals(null);
      expect(farming.address).to.not.equals(undefined);
    })

    it('has a name', async () => {
      let name = await farming.name();
      expect(name).to.equals(FarmingSCName);
    })

    it('has a token Address', async () => {

      let tokenAddr = await farming.tokenAddress();
      expect(tokenAddr).to.equals(lpToken.address);

    })

    it('has a reward Address', async () => {

      let tokenAddr = await farming.rewardTokenAddress();
      expect(tokenAddr).to.equals(rewardToken.address);

    })


    it('should be paused after deployment', async () => {
      const paused = await farming.isPaused();
      expect(paused).to.equals(true, "Contract is paused");
    })

    it('should set period to 0 during deployment', async () => {
      const period = await farming.period();
      expect(period).to.equals('0', "Period is set successfully");
    })

  })

  describe('Reset, reward and StartEnd Blocks', async () => {
    it('should not add 0 rewards', async () => {

      await expect(farming.resetAndsetStartEndBlock(0, 1000, 1100)).to.be.revertedWith("Reward must be positive")
    })

    it('should not add reward greater than allowance', async () => {
      const approval = eth(1000);
      const rewards = eth(2000);
      await rewardToken.approve(farming.address, approval);
      await expect(farming.resetAndsetStartEndBlock(rewards, 1000, 1100)).to.be.revertedWith("Make sure to add enough allowance");
    })

    it('should not add invalid parameters for start and end block', async () => {
      const currentBlock = await farming.currentBlock();
      const start = currentBlock + 5;
      const end = currentBlock + 15;
      await expect(farming.resetAndsetStartEndBlock(1, currentBlock - 1, currentBlock + 10)).to.be.revertedWith("Start should be more than current block");
      await expect(farming.resetAndsetStartEndBlock(1, start, start - 5)).to.be.revertedWith("End block should be greater than start");
    })

    it('should not allow others to set start and end block', async () => {
      await expect(farming.connect(fund).resetAndsetStartEndBlock(1, 10, 20)).to.be.revertedWith("Ownable: caller is not the owner");
    })

    it('should add reward amount and set the start, end block by the owner', async () => {
      const reward = eth(1000);
      const currentBlock = await farming.currentBlock();
      await farming.resetAndsetStartEndBlock(reward, currentBlock.toNumber() + 25, currentBlock.toNumber() + 125);
      const startBlock = await farming.startingBlock();
      expect(startBlock).to.equals(currentBlock.toNumber() + 25, "Starting block set successfully");
      const totalReward = await farming.totalReward();
      expect(totalReward).to.equals(reward, "Reward set successfully");
    })

    it('should not be paused after setting start and end block', async () => {
      const pause = await farming.isPaused();
      expect(pause).to.equals(false, "Is not paused");
    })

    it('should not allow users to stake before start', async () => {
      const stake = eth(1000);
      await lpToken.transfer(fund.address, stake);
      await lpToken.connect(fund).approve(farming.address, stake);
      await expect(farming.connect(fund).stake(stake)).to.be.revertedWith("Invalid period");
    })
  })

  describe('Users can stake, claim and withdraw rewards', async () => {

    it('should allow users to stake', async () => {
      const stake = eth(1000);
      const currentBlock = await farming.currentBlock();
      const start = await farming.startingBlock();
      if(currentBlock < start) {
        await mineUpTo(ethers.BigNumber.from(start.add(2)))
      }

      await farming.connect(fund).stake(stake);
      const userStakeDetails = await farming.deposits(fund.address);
      expect(userStakeDetails[0]).to.equals(stake, "Amount staked successfully");
    })

    it('should update user share in the pool', async () => {
      const userShare = await farming.fetchUserShare(fund.address);
      expect(userShare).to.equals('10000', "share set successfully");
    })

    it('should update claim rewards per block', async () => {
      const currentUserRew = await farming.calculate(fund.address);
      const currentBlock = await farming.currentBlock();
      await mineUpTo(ethers.BigNumber.from(currentBlock.add(1)))
      const newUserRew = await farming.calculate(fund.address);
      // const diff = newUserRew.toNumber() - currentUerRew.toNumber();
      const diff = newUserRew.sub(ethers.BigNumber.from(currentUserRew));
      const rewPerBlock = await farming.rewPerBlock();
      expect(rewPerBlock).to.equals(diff.toString(), "Rewards are calculated");
    })

    it('should change userShare as the pool increases', async () => {
      const stake = eth(1000);
      await lpToken.transfer(target.address, stake);
      await lpToken.connect(target).approve(farming.address, stake);
      await farming.connect(target).stake(stake);
      const userStakeShare1 = await farming.fetchUserShare(fund.address);
      const userStakeShare2 = await farming.fetchUserShare(target.address);
      expect(userStakeShare1).to.equals('5000', "User share updated");
      expect(userStakeShare2).to.equals('5000', "User share updated");
    })

    it('should allow users to claim correct rewards', async () => {
      const currentBlock = await farming.currentBlock();
      await mineUpTo(ethers.BigNumber.from(currentBlock.add(1)))
      const rew = await farming.calculate(fund.address);
      const rewardBalance = await rewardToken.balanceOf(fund.address);
      await farming.connect(fund).claimRewards();
      await mineUpTo(ethers.BigNumber.from(currentBlock.add(3)))

      const rew1 = await farming.calculate(fund.address);
      const newRewardBalance = await rewardToken.balanceOf(fund.address);
      const newRew = rew.add(ethers.BigNumber.from(rew1));
      const diff = newRewardBalance.sub(ethers.BigNumber.from(rewardBalance));
      expect(newRew).to.equals(diff.toString(), "User share updated");
    })

    it('should allow users to withdraw stakings', async () => {
      await farming.connect(target).emergencyWithdraw();
      const userDeposit = await farming.deposits(target.address);
      expect(userDeposit[0]).to.equals('0', "Withdraw is successfull");
      const hasStaked = await farming.hasStaked(target.address);
      expect(hasStaked).to.equals(false, "Has staked removed");
    })

    it('should allow users to add more liquidity', async () => {
      const stake = eth(1000);
      await lpToken.transfer(target.address, stake);
      await lpToken.connect(target).approve(farming.address, stake);
      await farming.connect(target).stake(stake);
      const newStake = eth(3000);
      await lpToken.transfer(fund.address, newStake);
      await lpToken.connect(fund).approve(farming.address, newStake);
      await farming.connect(fund).stake(newStake);
      const userShare1 = await farming.fetchUserShare(fund.address);
      expect(userShare1).to.equals('8000', "User share increased after adding of liquidity");
    })

    it('should not allow users to stake after the endingBlock', async () => {
      const currentBlock = await farming.currentBlock();
      const end = await farming.endingBlock();
      
      await mineUpTo(ethers.BigNumber.from(end.add(1)))

      const newStake = eth(3000);
      await lpToken.transfer(fund.address, newStake);
      await lpToken.connect(fund).approve(farming.address, newStake);
      await expect(farming.connect(fund).stake(newStake)).to.be.revertedWith("Invalid period");

    })

    it('should allow users to claim rewards in buffer period', async () => {
      const currentBlock = await farming.currentBlock();
      await mineUpTo(ethers.BigNumber.from(currentBlock.add(1)))
      const rew = await farming.calculate(fund.address);
      const rewardBalance = await rewardToken.balanceOf(fund.address);
      await farming.connect(fund).claimRewards();
      await mineUpTo(ethers.BigNumber.from(currentBlock.add(3)))

      const rew1 = await farming.calculate(fund.address);
      const newRewardBalance = await rewardToken.balanceOf(fund.address);
      const newRew = rew.add(ethers.BigNumber.from(rew1));
      const diff = newRewardBalance.sub(ethers.BigNumber.from(rewardBalance));
      expect(newRew).to.equals(diff.toString(), "Rewards are claimed correctly");
    })
  })

  describe("Post-lock period", async () => {
    it('should not allow users to reset the contract', async () => {
      await expect(farming.connect(fund).resetAndsetStartEndBlock(1, 1000, 1100)).to.be.revertedWith("Ownable: caller is not the owner")
    })

    it('should not add reward greater than allowance', async () => {
      const approval = eth(1000);
      const rewards = eth(2000);
      await rewardToken.approve(farming.address, approval.toString());
      await expect(farming.resetAndsetStartEndBlock(rewards.toString(), 1000, 1100)).to.be.revertedWith("Make sure to add enough allowance");
    })

    it('should not add invalid parameters for start and end block', async () => {
      const currentBlock = await farming.currentBlock();
      // console.log(currentBlock);
      const start = currentBlock + 5;
      const end = currentBlock + 15;
      await expect(farming.resetAndsetStartEndBlock(1, currentBlock - 1, currentBlock + 10)).to.be.revertedWith("Start should be more than current block");
      await expect(farming.resetAndsetStartEndBlock(1, start, start - 5)).to.be.revertedWith("End block should be greater than start");
    })

    it('should not allow others to set start and end block', async () => {
      await expect(farming.connect(fund).resetAndsetStartEndBlock(1, 10, 20)).to.be.revertedWith("Ownable: caller is not the owner");
    })

    it('should add reward amount and set the start, end block by the owner', async () => {
      const reward = eth(1000);
      const currentBlock = await farming.currentBlock();
      await farming.resetAndsetStartEndBlock(reward, currentBlock.toNumber() + 15, currentBlock.toNumber() + 115);
      const startBlock = await farming.startingBlock();
      expect(startBlock).to.equals((currentBlock.toNumber() + 15).toString(), "Starting block set successfully");
      const totalReward = await farming.totalReward();
      expect(totalReward).to.equals(reward, "Reward set successfully");
    })

    it('should not be paused after setting start and end block', async () => {
      const pause = await farming.isPaused();
      expect(pause).to.equals(false, "Is not paused");
    })

    it('should increment the period', async () => {
      const period = await farming.period();
      expect(period).to.equals('2', "Period is set correctly");
    })
  })

  describe("Users can renew and claim old rewards", async () => {
    it('should not allow users to claim untill renew', async () => {
      
      const start = await farming.startingBlock();
      await mineUpTo(ethers.BigNumber.from(start.add(1)))
      await expect(farming.connect(fund).claimRewards()).to.be.revertedWith("No stakes found for user");
    })

    it('should allow users to renew', async () => {
      await farming.connect(fund).renew();
      const userDeposits = await farming.deposits(fund.address);
      const period = await farming.period();
      expect(userDeposits[4]).to.equals(period.toString(), "Renewed successfully");
    })

    it('should allow users to claim correct rewards', async () => {
      const currentBlock = await farming.currentBlock();
      await mineUpTo(ethers.BigNumber.from(currentBlock.add(1)))

      const rew = await farming.calculate(fund.address);
      const rewardBalance = await rewardToken.balanceOf(fund.address);
      await farming.connect(fund).claimRewards();
      await mineUpTo(ethers.BigNumber.from(currentBlock.add(3)))
      const rew1 = await farming.calculate(fund.address);
      const newRewardBalance = await rewardToken.balanceOf(fund.address);
      const newRew = rew.add(ethers.BigNumber.from(rew1));
      const diff = newRewardBalance.sub(ethers.BigNumber.from(rewardBalance));
      expect(newRew).to.equals(diff.toString(), "Rewards are claimed correctly");
    })

    it('should allow users to claim rewards for old period', async () => {

      const oldRewards = await farming.viewOldRewards(target.address);
      const rewBalance = await rewardToken.balanceOf(target.address);
      await farming.connect(target).claimOldRewards();
      const newBalance = await rewardToken.balanceOf(target.address);
      const diff = newBalance.sub(ethers.BigNumber.from(rewBalance));
      expect(diff).to.equals(oldRewards.toString(), "Old rewards claimed successfully");
    })

    it('should allow users to withdraw at any time', async () => {
      await farming.connect(target).emergencyWithdraw();
      const userDeposits = await farming.deposits(target.address);
      expect(userDeposits[0]).to.equals('0', "Withdraw successfull");
    })

    it('should allow users to exit', async () => {
      const currentBlock = await farming.currentBlock();
      await mineUpTo(ethers.BigNumber.from(currentBlock.add(1)))
      const tokenBalance = await lpToken.balanceOf(fund.address);
      const amount = await farming.deposits(fund.address);
      await mineUpTo(ethers.BigNumber.from(currentBlock.add(3)))
      await farming.connect(fund).withdraw();
      await mineUpTo(ethers.BigNumber.from(currentBlock.add(5)))
      const newtokenBalance = await lpToken.balanceOf(fund.address);
      const diffT = newtokenBalance.sub(ethers.BigNumber.from(tokenBalance));
      expect(amount[0]).to.equals(diffT.toString(), "LP tokens are claimed correctly");
    })
  })

});
