// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

// OpenZeppelin dependencies
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ILinearVesting.sol";

/**
 * @title LinearVesting
 */
contract LinearVesting is ILinearVesting, AccessControl, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

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
        uint256 price;
        uint256 refundFee;
    }

    event AddAdmin(address indexed _account);
    event RemoveAdmin(address indexed _account);


    string public name = "CWF Vesting";
    // address of the ERC20 token
    IERC20 private _token;
    mapping(address => uint256) public released;
    mapping(address => bool) public initialCliamed;
    mapping(string => mapping(address => ReleaseSchedule))
        public releaseScheduleByTag;
    uint64 public divisor = 100000; // 1% = 1000

    /**
     * @dev Creates a vesting contract.
     */
    constructor() {
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Throws if the sender is not the admin.
     */
    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "TokenVesting: DOES_NOT_HAVE_ADMIN_ROLE"
        );
        _;
    }


    /**
     * @dev Sets the total claim amount for each account for tagId.
     * @param tagId tag title
     * @param account user wallet address
     * @param amount total claim amount
     * @param paymentToken token address which user invested
     * @param price claim token amount per payment token
     * @param refundFee fee amount when user refunds the investment 1000 = 1%
     */
    function setCrowdfundingWhitelist(
        string calldata tagId,
        address account,
        uint256 amount,
        address paymentToken,
        uint256 price,
        uint256 refundFee
    ) external override onlyAdmin {
        ReleaseSchedule storage schedule = releaseScheduleByTag[tagId][account];
        schedule.amount += amount;
        schedule.paymentToken = paymentToken;
        schedule.price = price;
        schedule.refundFee = refundFee;
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
        _grantRole(ADMIN_ROLE, contractSetup.admin);

    }

    /**
     * @notice Withdraw the specified amount if possible.
     * @param amount the amount to withdraw
     */
    function withdraw(address token, uint256 amount) external onlyOwner {
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
     * @notice Refund the specified amount if possible.
     * @param amount the amount to refund
     */
    function refund(string calldata tagId, uint256 amount) external nonReentrant {
        uint256 currentTime = getCurrentTime();
        require(
            currentTime <= start,
            "TokenVesting: Presale is finished."
        );

        ReleaseSchedule storage schedule = releaseScheduleByTag[tagId][
            msg.sender
        ];
        uint256 refundAmount = amount.mul(divisor - schedule.refundFee).div(
            divisor
        );
        IERC20(schedule.paymentToken).transfer(msg.sender, refundAmount);
        schedule.amount = schedule.amount.sub(amount);
    }

    /**
     * @notice claim vested amount of tokens.
     */
    function claim(string calldata tagId) external nonReentrant {
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
        uint256 totalAmount = schedule.amount.mul(schedule.price).div(divisor);

        // If the current time is after the vesting period, all tokens are releasable,
        // minus the amount already released.
        if (currentTime <= start.add(cliff)) {
            return totalAmount.mul(initialUnlockPercent).div(divisor);
        } else if (currentTime >= start.add(duration)) {
            return totalAmount;
        } else {
            uint256 claimableDuration = currentTime.sub(start + cliff);
            // Subtract the amount already released and return.
            uint256 amountPerSecond = totalAmount.div(duration - cliff);
            return
                claimableDuration.mul(amountPerSecond).add(
                    totalAmount.mul(initialUnlockPercent).div(divisor)
                );
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
     * @dev Adds account to blacker list
     * @param _account The address to blacklist
     */
    function addAdmin(address _account) external onlyAdmin {
        _grantRole(ADMIN_ROLE, _account);
        emit AddAdmin(_account);
    }

    /**
     * @dev Removes account to blacker list
     * @param _account The address to blacklist
     */
    function removeAdmin(address _account) external onlyAdmin {
        _revokeRole(ADMIN_ROLE, _account);
        emit RemoveAdmin(_account);
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
}
