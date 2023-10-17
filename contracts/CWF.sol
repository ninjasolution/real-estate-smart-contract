//SPDX-License-Identifier: Unlicense
//Declare the version of solidity to compile this contract.
//This must match the version of solidity in your hardhat.config.js file
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract CWF is ERC20, AccessControl, Ownable, Pausable {
    using SafeMath for uint256;

    bytes32 public constant BLACKER_ROLE = keccak256("BLACKER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(address => bool) public blacklisted;
    mapping(address => bool) public whitelisted;

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);
    event Whitelisted(address indexed _account);
    event AddAdmin(address indexed _account);
    event RemoveAdmin(address indexed _account);
    event AddBlacker(address indexed _account);
    event RemoveBlacker(address indexed _account);
    event UpdateTaxFee(uint16 buyFee, uint256 sellFee);
    event UpateTaxWallets(
        address indexed _charityWallet,
        address indexed _devWallet
    );

    uint16 public _maxBalancePercent = 100; // 1%
    uint16 public _percentDivisor = 10000; // 1% = 100

    // Address List
    address public charityWallet = 0xA4D1E481417bBB1E472152A4ABD99D9E161Ba8f1;
    address public devWallet = 0xa415D52dd2bf10e2406e9e75a7F411EFCf025e64;

    // Tax System
    uint256 public maxTaxFee = 1000; // 10%
    uint256 public _feeBuyTotal = 200; // 5%
    uint256 public _feeSellTotal = 300; // 5%
    uint256 public _devFeePercent = 2000; // 1%

    // Uniswap
    IUniswapV2Router02 public swapRouter;
    address public swapPair;

    constructor(
        address router,
        address _charityWallet,
        address _devWallet
    ) ERC20("Federation World Contact", "CWF") {
        _mint(msg.sender, 700_000_000 * 10 ** 18);
        _grantRole(BLACKER_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        IUniswapV2Router02 _uniswapRouter = IUniswapV2Router02(router);
        swapRouter = _uniswapRouter;
        swapPair = IUniswapV2Factory(_uniswapRouter.factory()).createPair(
            address(this),
            _uniswapRouter.WETH()
        );
        charityWallet = _charityWallet;
        devWallet = _devWallet;
    }

    /**
     * @dev Throws if the sender is not the admin.
     */
    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "CWF: DOES_NOT_HAVE_ADMIN_ROLE"
        );
        _;
    }

    /**
     * @dev Throws if the sender is not the blacker.
     */
    modifier onlyBlacker() {
        require(
            hasRole(BLACKER_ROLE, msg.sender),
            "CWF: DOES_NOT_HAVE_BLACKER_ROLE"
        );
        _;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(
            !(blacklisted[from] && !blacklisted[to]),
            "CWF: Black listed account."
        );

        if (!whitelisted[to] && from != address(swapPair) && to != owner()) {
            uint256 nextBalance = balanceOf(to);
            nextBalance += amount;
            require(
                nextBalance <=
                    totalSupply().mul(_maxBalancePercent).div(_percentDivisor),
                "CWF: Anti whale policy."
            );
        }

        uint256 taxAmount = 0;

        if (msg.sender == owner()) {
            taxAmount = 0;
        } else if (to == address(swapPair)) {
            taxAmount = (amount * _feeSellTotal) / _percentDivisor;
        } else if (from == address(swapPair)) {
            taxAmount = (amount * _feeBuyTotal) / _percentDivisor;
        }

        super._transfer(from, to, amount - taxAmount);

        if (taxAmount > 0) {
            uint256 amountForDev = taxAmount.mul(_devFeePercent).div(
                _percentDivisor
            );
            super._transfer(from, devWallet, amountForDev);
            super._transfer(from, charityWallet, taxAmount - amountForDev);
        }
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
     */
    function addWhitelist(address _account) external onlyAdmin {
        whitelisted[_account] = true;
        emit Whitelisted(_account);
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
     */
    function addBlacklist(address _account) external onlyBlacker {
        blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    /**
     * @dev Removes account from blacklist
     * @param _account The address to remove from the blacklist
     */
    function removeBlacklist(address _account) external onlyBlacker {
        blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
     */
    function addAdmin(address _account) external onlyOwner {
        _grantRole(ADMIN_ROLE, _account);
        emit AddAdmin(_account);
    }

    /**
     * @dev Adds account to blacker list
     * @param _account The address to blacklist
     */
    function addBlacker(address _account) external onlyAdmin {
        _grantRole(BLACKER_ROLE, _account);
        emit AddBlacker(_account);
    }

    /**
     * @dev Removes account to blacker list
     * @param _account The address to blacklist
     */
    function removeBlacker(address _account) external onlyAdmin {
        _revokeRole(BLACKER_ROLE, _account);
        emit RemoveBlacker(_account);
    }

    function udpateTaxWallets(
        address _charityWallet,
        address _devWallet
    ) external onlyOwner {
        charityWallet = _charityWallet;
        devWallet = _devWallet;

        emit UpateTaxWallets(_charityWallet, _devWallet);
    }

    function updateTaxFee(uint16 buyFee, uint16 sellFee) external onlyOwner {
        require(
            buyFee <= maxTaxFee && sellFee <= maxTaxFee,
            "CWF: Exceed Max Tax fee"
        );
        _feeBuyTotal = buyFee;
        _feeSellTotal = sellFee;

        emit UpdateTaxFee(buyFee, sellFee);
    }

    receive() external payable {}
}
