const { expect } = require("chai");
const { constants } = require("ethers");
const { UniswapV2Deployer, ethers } = require("hardhat");

function eth(amount) {
    return ethers.utils.parseEther(amount.toString())
}



describe("CWF", function () {


    let token, deployer, fund, dev;
    let pair, _weth9, _router;
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deploy() {
        [deployer, fund, dev] = await ethers.getSigners();

        // deploy the uniswap v2 protocol
        const { factory, router, weth9 } = await UniswapV2Deployer.deploy(deployer);

        // deploy our token
        const Token = await ethers.getContractFactory("CWF")
        token = await Token.deploy(router.address, fund.address, dev.address)
        await token.deployed()

        // get our pair
        pair = new ethers.Contract(await token.swapPair(), UniswapV2Deployer.Interface.IUniswapV2Pair.abi)

        // approve the spending
        await weth9.approve(router.address, eth(1000))
        await token.approve(router.address, eth(1000))

        // add liquidity
        await router.addLiquidityETH(
            token.address,
            eth(500),
            eth(500),
            eth(10),
            deployer.address,
            constants.MaxUint256,
            { value: eth(10) }
        )

        _weth9 = weth9;
        _router = router;
    }

    before(async () => {
        await deploy();
    })


    describe("Transfer", function () {

        it("shouldn't tax on transfer", async function () {

            await expect(token.transfer(dev.address, eth(100))).to.changeTokenBalances(
                token,
                [deployer, fund, dev],
                [eth(100 * -1), 0, eth(100)]
            )

        })

    })

    describe("Swap", function () {

        it("should tax on buy", async function () {

            await expect(_router.swapETHForExactTokens(
                eth(100),
                [_weth9.address, token.address],
                deployer.address,
                constants.MaxUint256,
                { value: eth(100) }
            )).to.changeTokenBalances(token, [deployer, dev, pair], [eth(98), eth(0.4), eth(100 * -1)])
        })

        it("should tax on sell", async function () {
            // since we have a fee, we must call SupportingFeeOnTransferTokens
            await expect(_router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                eth(100),
                1,
                [token.address, _weth9.address],
                deployer.address,
                constants.MaxUint256,
            )).to.changeTokenBalances(token, [deployer, dev, pair], [eth(100 * -1), eth(0.6), eth(97)])
        })
    })


    describe("Permission", function () {

        it("Add Admin", async function () {

            await expect(token.connect(fund).addBlacker(fund.address)).to.be.revertedWith("CWF: DOES_NOT_HAVE_ADMIN_ROLE");
            await token.addAdmin(fund.address);
        })

        it("Add Blacklist", async function () {
            await expect(token.connect(fund).addBlacklist(dev.address)).to.be.revertedWith("CWF: DOES_NOT_HAVE_BLACKER_ROLE");
            await token.addBlacker(fund.address);
            await token.connect(fund).addBlacklist(dev.address);
        })

        it("Add wallets and fees", async function () {
            await expect(token.connect(fund).udpateTaxWallets(fund.address, dev.address)).to.be.revertedWith("Ownable: caller is not the owner");
            await token.udpateTaxWallets(fund.address, dev.address);
            await token.updateTaxFee(500, 100);
            await expect(token.updateTaxFee(500, 1200)).to.be.revertedWith("CWF: Exceed Max Tax fee");
        })
    })



});
