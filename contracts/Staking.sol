//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Staking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public name;
    /**
     *  @dev Structs to store user staking data.
     */
    struct Deposits {
        uint256 depositAmount;
        uint256 depositTime;
        uint256 endTime;
        uint64 userIndex;
        uint256 rewards;
        bool paid;
    }

    /**
     *  @dev Structs to store interest rate change.
     */
    struct Rates {
        uint64 newInterestRate;
        uint256 timeStamp;
        uint256 duration;
    }

    mapping(uint64 => mapping(address => Deposits)) public deposits;
    mapping(uint64 => mapping(uint64 => Rates)) public rateAndDurations; // rateAndDurations[index][historyIndex][Rates]
    mapping(uint64 => uint64) public index; // index[index][currentId] rate history index
    mapping(address => bool) private hasStaked;

    uint256[] public durations;

    address public stakeTokenAddr;
    address public rewardTokenAddr;
    uint256 public stakedBalance;
    uint256 public stakedTotal;
    uint256 public totalParticipants;
    bool public isStopped;

    IERC20 public ERC20Interface;

    /**
     *  @dev Emitted when user stakes 'stakedAmount' value of tokens
     */
    event Staked(
        address indexed token,
        address indexed staker_,
        uint256 stakedAmount_
    );

    /**
     *  @dev Emitted when user withdraws his stakings
     */
    event PaidOut(
        address indexed token,
        address indexed staker_,
        uint256 amount_,
        uint256 reward_
    );

    event RateAndLockduration(
        uint64 index,
        uint64 newRate,
        uint256 lockDuration,
        uint256 time
    );

    event RewardsAdded(uint256 rewards, uint256 time);

    event StakingStopped(bool status, uint256 time);

    /**
     *   @dev deploy staking contract
     *   @param owner_ staking contract owner
     *   @param name_ name of the contract
     *   @param stakeTokenAddr_ token address for staking
     *   @param rewardTokenAddr_ token address for reward
     *   @param durations_ array of duration period
     *   @param rates_ array of rate for each duration
     */
    constructor(
        address owner_,
        string memory name_,
        address stakeTokenAddr_,
        address rewardTokenAddr_,
        uint256[] memory durations_,
        uint64[] memory rates_
    ) {
        require(stakeTokenAddr_ != address(0), "Zero token address");
        require(
            durations_.length == rates_.length,
            "Both array length should be same"
        );
        stakeTokenAddr = stakeTokenAddr_;
        rewardTokenAddr = rewardTokenAddr_;
        // uint256[4] memory _durations = [uint256(2592000), 5184000, 15552000, 23328000]; //30 days, 90 days, 180 days, 270 days
        // uint64[4] memory _rates = [uint64(32), 123, 297, 518]; // APR: 0.32%, 1.23%, 2.97%, 5.18% APR: 4%, 5%, 6%, 7%
        for (uint64 i = 0; i < durations_.length; i++) {
            addRateAndDuration(rates_[i], durations_[i]);
        }
        name = name_;
        transferOwnership(owner_);
    }

    /**
     *  @dev to add a new rate and duration
     *  @param rate_ to set a new rate
     *  @param duration_ to set a new duration
     */
    function addRateAndDuration(
        uint64 rate_,
        uint256 duration_
    ) public onlyOwner {
        require(rate_ != 0, "Zero interest rate");
        rateAndDurations[uint64(durations.length)][0] = Rates(
            rate_,
            block.timestamp,
            duration_
        );
        durations.push(duration_);
    }

    /**
     *  @dev to add a new rate and duration
     *  @param index_ to set index of lock duration days
     *  @param rate_ to set a new rate of old duration
     */
    function setRate(uint64 index_, uint64 rate_) external onlyOwner {
        require(rate_ != 0, "Zero interest rate");
        uint256 duration = rateAndDurations[index_][index[index_]].duration;
        index[index_]++;
        rateAndDurations[index_][index[index_]] = Rates(
            rate_,
            block.timestamp,
            duration
        );
        emit RateAndLockduration(
            index[index_],
            rate_,
            duration,
            block.timestamp
        );
    }

    function changeStakingStatus(bool _status) external onlyOwner {
        isStopped = _status;
        emit StakingStopped(_status, block.timestamp);
    }

    /**
     *  @dev to add rewards to the staking contract
     *  @param rewardAmount rewards to be added to the staking contract
     *  once the allowance is given to this contract for 'rewardAmount' by the user
     */
    function addReward(
        uint256 rewardAmount
    ) external _realAddress(msg.sender) returns (bool) {
        require(rewardAmount > 0, "Reward must be positive");
        ERC20Interface = IERC20(rewardTokenAddr);
        ERC20Interface.safeTransferFrom(msg.sender, address(this), rewardAmount);
        emit RewardsAdded(rewardAmount, block.timestamp);
        return true;
    }

    /**
     *  @dev to stake 'amount' value of tokens
     *  @param durationIndex Index number of duration
     *  @param amount Amount to be staked
     *  once the user has given allowance to the staking contract
     */

    function stake(
        uint64 durationIndex,
        uint256 amount
    )
        external
        _realAddress(msg.sender)
        _hasAllowance(msg.sender, amount)
        returns (bool)
    {
        require(amount > 0, "Can't stake 0 amount");
        require(!isStopped, "Staking paused");
        return (_stake(durationIndex, msg.sender, amount));
    }

    function _stake(
        uint64 durationIndex,
        address from,
        uint256 amount
    ) private returns (bool) {
        if (!hasStaked[from]) {
            hasStaked[from] = true;

            deposits[durationIndex][from] = Deposits(
                amount,
                block.timestamp,
                block.timestamp.add((durations[durationIndex])),
                index[durationIndex],
                0,
                false
            );
            totalParticipants = totalParticipants.add(1);
        } else {
            require(
                block.timestamp < deposits[durationIndex][from].endTime,
                "Lock expired, please withdraw and stake again"
            );
            uint256 newAmount = deposits[durationIndex][from].depositAmount.add(
                amount
            );
            uint256 rewards = _calculate(durationIndex, from, block.timestamp)
                .add(deposits[durationIndex][from].rewards);

            deposits[durationIndex][from] = Deposits(
                newAmount,
                block.timestamp,
                block.timestamp.add((durations[durationIndex])),
                index[durationIndex],
                rewards,
                false
            );
        }
        stakedBalance = stakedBalance.add(amount);
        stakedTotal = stakedTotal.add(amount);
        require(_payMe(from, amount), "Payment failed");
        emit Staked(stakeTokenAddr, from, amount);

        return true;
    }

    /**
     * @dev withdraw the token which staked on the contract
     * @param durationIndex index of duration
     */
    function withdraw(
        uint64 durationIndex
    ) public _realAddress(msg.sender) returns (bool) {
        require(hasStaked[msg.sender], "No stakes found for user");
        require(!deposits[durationIndex][msg.sender].paid, "Already paid out");
        require(
            block.timestamp >= deposits[durationIndex][msg.sender].endTime,
            "Requesting before lock time"
        );
        uint256 reward = _calculate(
            durationIndex,
            msg.sender,
            deposits[durationIndex][msg.sender].endTime
        );
        reward = reward.add(deposits[durationIndex][msg.sender].rewards);
        uint256 amount = deposits[durationIndex][msg.sender].depositAmount;

        require(
            rewardBalance() >= amount,
            "Staking: Insufficient reward token balance"
        );

        stakedBalance = stakedBalance.sub(amount);
        deposits[durationIndex][msg.sender].paid = true;
        hasStaked[msg.sender] = false;
        totalParticipants = totalParticipants.sub(1);

        if (_payDirect(rewardTokenAddr, msg.sender, reward)) {
            emit PaidOut(rewardTokenAddr, msg.sender, amount, reward);
        }
        if (
            block.timestamp >= deposits[durationIndex][msg.sender].endTime &&
            _payDirect(stakeTokenAddr, msg.sender, amount)
        ) {
            emit PaidOut(stakeTokenAddr, msg.sender, amount, reward);
        }

        return true;
    }

    /**
     * @dev claim the reward token
     * @param durationIndex index of duration
     */
    function claim(
        uint64 durationIndex
    ) public _realAddress(msg.sender) returns (bool) {
        require(!deposits[durationIndex][msg.sender].paid, "Already paid out");
        uint256 reward = _calculate(
            durationIndex,
            msg.sender,
            deposits[durationIndex][msg.sender].endTime
        );
        require(reward >= 0, "No reward");
        reward = reward.add(deposits[durationIndex][msg.sender].rewards);
        uint256 amount = deposits[durationIndex][msg.sender].depositAmount;

        require(
            rewardBalance() >= amount,
            "Staking: Insufficient reward token balance"
        );

        deposits[durationIndex][msg.sender].rewards = 0;

        if (_payDirect(rewardTokenAddr, msg.sender, reward)) {
            emit PaidOut(rewardTokenAddr, msg.sender, amount, reward);
        }

        return true;
    }

    /**
     * @dev withdraw the token which staked token without claim
     * @param durationIndex index of duration
     */
    function emergencyWithdraw(
        uint64 durationIndex
    ) external _realAddress(msg.sender) returns (bool) {
        require(hasStaked[msg.sender], "No stakes found for user");
        require(!deposits[durationIndex][msg.sender].paid, "Already paid out");

        return (_emergencyWithdraw(durationIndex, msg.sender));
    }

    function _emergencyWithdraw(
        uint64 durationIndex,
        address from
    ) private returns (bool) {
        uint256 amount = deposits[durationIndex][from].depositAmount;
        stakedBalance = stakedBalance.sub(amount);
        deposits[durationIndex][from].paid = true;
        hasStaked[from] = false; //Check-Effects-Interactions pattern
        totalParticipants = totalParticipants.sub(1);

        bool principalPaid = _payDirect(rewardTokenAddr, from, amount);
        require(principalPaid, "Error paying");
        emit PaidOut(stakeTokenAddr, from, amount, 0);

        return true;
    }

    /**
     * @dev to calculate the rewards based on user staked 'amount'
     * @param durationIndex index of duration
     * @param from User wallet address
     */
    function calculate(
        uint64 durationIndex,
        address from
    ) external view returns (uint256) {
        return
            _calculate(
                durationIndex,
                from,
                deposits[durationIndex][from].endTime
            );
    }

    function _calculate(
        uint64 durationIndex,
        address from,
        uint256 endTime
    ) private view returns (uint256) {
        if (!hasStaked[from]) return 0;
        (uint256 amount, uint256 depositTime, uint64 userIndex) = (
            deposits[durationIndex][from].depositAmount,
            deposits[durationIndex][from].depositTime,
            deposits[durationIndex][from].userIndex
        );

        amount = amount
            .div(10 ** IERC20Metadata(stakeTokenAddr).decimals())
            .mul(10 ** IERC20Metadata(rewardTokenAddr).decimals());

        uint256 time;
        uint256 interest;
        uint256 _lockduration = deposits[durationIndex][from].endTime.sub(
            depositTime
        );
        for (uint64 i = userIndex; i < index[durationIndex]; i++) {
            //loop runs till the latest index/interest rate change
            if (endTime < rateAndDurations[durationIndex][i + 1].timeStamp) {
                //if the change occurs after the endTime loop breaks
                break;
            } else {
                time = rateAndDurations[durationIndex][i + 1].timeStamp.sub(
                    depositTime
                );
                interest = amount
                    .mul(rateAndDurations[durationIndex][i].newInterestRate)
                    .mul(time)
                    .div(_lockduration.mul(10000));
                amount = amount.add(interest);
                depositTime = rateAndDurations[durationIndex][i + 1].timeStamp;
                userIndex++;
            }
        }

        if (depositTime < endTime) {
            //final calculation for the remaining time period
            time = endTime.sub(depositTime);

            interest = time
                .mul(amount)
                .mul(rateAndDurations[durationIndex][userIndex].newInterestRate)
                .div(_lockduration.mul(10000));
        }

        return (interest);
    }

    function _payMe(address payer, uint256 amount) private returns (bool) {
        return _payTo(payer, address(this), amount);
    }

    function _payTo(
        address allower,
        address receiver,
        uint256 amount
    ) private _hasAllowance(allower, amount) returns (bool) {
        ERC20Interface = IERC20(stakeTokenAddr);
        ERC20Interface.safeTransferFrom(allower, receiver, amount);
        return true;
    }

    function _payDirect(
        address token,
        address to,
        uint256 amount
    ) private returns (bool) {
        ERC20Interface = IERC20(token);
        ERC20Interface.safeTransfer(to, amount);
        return true;
    }

    function rewardBalance() public view returns (uint256) {
        return IERC20(rewardTokenAddr).balanceOf(address(this));
    }

    modifier _realAddress(address addr) {
        require(addr != address(0), "Zero address");
        _;
    }

    modifier _hasAllowance(address allower, uint256 amount) {
        // Make sure the allower has provided the right allowance.
        ERC20Interface = IERC20(stakeTokenAddr);
        uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));
        require(amount <= ourAllowance, "Make sure to add enough allowance");
        _;
    }
}
