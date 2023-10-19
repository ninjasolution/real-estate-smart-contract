// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

// OpenZeppelin dependencies
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/ILinearVesting.sol";

/**
 * @title LinearVesting
 */
contract LinearVesting is ILinearVesting, ReentrancyGuard {
    using SafeMath for uint256;

    // cliff period in seconds
    uint256 public cliff;
    // unlock percent at first time
    uint256 public initialUnlockPercent;
    // start time of the vesting period
    uint256 public start;
    // duration of the vesting period in seconds
    uint256 public duration;
    // total amount of tokens to be released at the end of the vesting
    uint256 public amountTotal;
    // amount of tokens released
    uint256 public totalReleased;

    struct ReleaseSchedule {
        uint256 amount;
        address paymentToken;
        uint256 amountPerPaymentToken;
        uint256 refundFee;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    address private _owner;
    string public name = "CWF Vesting";
    // address of the ERC20 token
    IERC20 private _token;
    mapping(address => uint256) public released;
    mapping(address => bool) public initialCliamed;
    mapping(string => mapping(address => ReleaseSchedule))
        public releaseScheduleByTag;
    uint64 public percentDivisor = 100000; // 1% = 1000

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Creates a vesting contract.
     * @param owner_ address of the contract
     * @param name_ name of the contract
     */
    constructor(address owner_, string memory name_) {
        _transferOwnership(owner_);
        name = name_;
    }

    /**
     * @dev Sets the total claim amount for each account for tagId.
     * @param tagId tag title
     * @param account user wallet address
     * @param amount total claim amount
     * @param paymentToken token address which user invested
     * @param amountPerPaymentToken claim token amount per payment token
     * @param refundFee fee amount when user refunds the investment 1000 = 1%
     */
    function setCrowdfundingWhitelist(
        string calldata tagId,
        address account,
        uint256 amount,
        address paymentToken,
        uint256 amountPerPaymentToken,
        uint256 refundFee
    ) external override {
        releaseScheduleByTag[tagId][account] = ReleaseSchedule(
            amount,
            paymentToken,
            amountPerPaymentToken,
            refundFee
        );
    }

    /**
     * @dev Creates a vesting contract.
     * @param contractSetup initialize of the Presale Vesting
     * @param vestingSetup setup of the Presale Vesting contract
     */
    function initializeCrowdfunding(
        ContractSetup calldata contractSetup,
        VestingSetup calldata vestingSetup
    ) external onlyOwner {
        // Check that the token address is not 0x0.
        require(
            contractSetup.vestedToken != address(0),
            "vestingContract_ZERO_ADDRESS"
        );
        //Set the token address.
        _token = IERC20(contractSetup.vestedToken);

        require(
            vestingSetup.duration > 0,
            "TokenVesting: duration must be > 0"
        );
        require(
            contractSetup.totalTokenOnSale > 0,
            "TokenVesting: amount must be > 0"
        );
        require(
            vestingSetup.duration >= vestingSetup.cliff,
            "TokenVesting: duration must be >= cliff"
        );

        cliff = vestingSetup.cliff;
        initialUnlockPercent = vestingSetup.initialUnlockPercent; //20%
        start = vestingSetup.startTime;
        duration = vestingSetup.duration;
        amountTotal = contractSetup.totalTokenOnSale;
        totalReleased = 0;
    }

    /**
     * @dev This function is called for plain Ether transfers, i.e. for every call with empty calldata.
     */
    receive() external payable {}

    /**
     * @dev Fallback function is executed if none of the other functions match the function
     * identifier or no data was provided with the function call.
     */
    fallback() external payable {}

    /**
     * @notice Withdraw the specified amount if possible.
     * @param amount the amount to withdraw
     */
    function withdraw(
        address token,
        uint256 amount
    ) external nonReentrant onlyOwner {
        require(
            getWithdrawableAmount() >= amount,
            "TokenVesting: not enough withdrawable funds"
        );
        /*
         * @dev Replaced owner() with msg.sender => address of WITHDRAWER_ROLE
         */
        IERC20(token).transfer(msg.sender, amount);
    }

    /**
     * @notice Withdraw the specified amount if possible.
     * @param tagId the amount to withdraw
     */
    function refund(
        string calldata tagId,
        uint256 amount
    ) external nonReentrant {

        uint256 currentTime = getCurrentTime();
        require(currentTime <= start, "LinearVesting: Presale is finished.");
        
        ReleaseSchedule storage schedule = releaseScheduleByTag[tagId][msg.sender];
        uint256 refundAmount = amount.mul(percentDivisor - schedule.refundFee);
        IERC20(schedule.paymentToken).transfer(msg.sender, refundAmount);
        schedule.amount = schedule.amount.sub(amount);
    }

    /**
     * @notice claim vested amount of tokens.
     */
    function claim(string calldata tagId) public nonReentrant {
        uint256 claimableAmount = _computeReleasableAmount(tagId, msg.sender);
        uint256 rewardableAmount = claimableAmount - released[msg.sender];
        require(
            rewardableAmount > 0,
            "TokenVesting: cannot release tokens, not enough vested tokens"
        );

        totalReleased = totalReleased + rewardableAmount;
        released[msg.sender] = claimableAmount;

        _token.transfer(msg.sender, rewardableAmount);
    }

    /**
     * @dev Returns the address of the ERC20 token managed by the vesting contract.
     */
    function getToken() external view override returns (address) {
        return address(_token);
    }

    /**
     * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
     * @return the vested amount
     */
    function computeReleasableAmount(
        string calldata tagId,
        address account
    ) external view returns (uint256) {
        return _computeReleasableAmount(tagId, account);
    }

    /**
     * @dev Returns the amount of tokens that can be withdrawn by the owner.
     * @return the amount of tokens
     */
    function getWithdrawableAmount() public view returns (uint256) {
        return _token.balanceOf(address(this)) - amountTotal;
    }

    /**
     * @dev Computes the releasable amount of tokens for a vesting schedule.
     * @return the amount of releasable tokens
     */
    function _computeReleasableAmount(
        string calldata tagId,
        address account
    ) internal view returns (uint256) {
        // Retrieve the current time.
        uint256 currentTime = getCurrentTime();
        ReleaseSchedule memory schedule = releaseScheduleByTag[tagId][account];
        uint256 totalAmount = schedule.amount
            .mul(10 ** (IERC20Metadata(address(_token)).decimals() - IERC20Metadata(schedule.paymentToken).decimals()))
            .mul(schedule.amountPerPaymentToken);

        // If the current time is after the vesting period, all tokens are releasable,
        // minus the amount already released.
        if (currentTime <= start.add(cliff)) {
            return totalAmount.mul(initialUnlockPercent).div(percentDivisor);
        } else if (currentTime >= start.add(duration)) {
            return amountTotal;
        } else {
            uint256 claimableDuration = currentTime.sub(start + cliff);
            // Subtract the amount already released and return.
            uint256 amountPerSecond = totalAmount.div(duration - cliff);
            return claimableDuration.mul(amountPerSecond);
        }
    }

    /**
     * @dev Returns the current time.
     * @return the current timestamp in seconds.
     */
    function getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(
        address newOwner
    ) external virtual override onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
