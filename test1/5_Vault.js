const { expect } = require("chai");
const { constants } = require("ethers");
const { UniswapV2Deployer, ethers } = require("hardhat");

function eth(amount) {
    return ethers.utils.parseEther(amount.toString())
}



describe("Vault", function () {


    let token, vault, deployer, fund, dev;
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

        const Vault = await ethers.getContractFactory("Vault")
        vault = await Vault.deploy(router.address)
        await token.deployed()

        weth9.approve(vault.address, eth(3000));
        weth9.transfer(vault.address, eth(3000));

        token.approve(vault.address, eth(3000));
        token.transfer(vault.address, eth(3000));

        // get our pair
        pair = new ethers.Contract(await token.swapPair(), UniswapV2Deployer.Interface.IUniswapV2Pair.abi)

        // approve the spending
        await weth9.approve(router.address, eth(1000000))
        await token.approve(router.address, eth(1000000))

        // add liquidity
        await router.addLiquidityETH(
            token.address,
            eth(5000),
            eth(5000),
            eth(1000),
            deployer.address,
            constants.MaxUint256,
            { value: eth(1000) }
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

    describe("Withdraw", function () {

        it("withdraw some token to fund wallet", async function () {

            await expect(vault.withdrawToken(token.address, eth(1000), fund.address)).to.changeTokenBalances(
                token,
                [vault, fund, dev],
                [eth(1000 * -1), eth(1000), 0]
            )

        })

        // it("withdraw entire token to fund wallet", async function () {

        //     await expect(vault.withdrawEntireToken(token.address, fund.address)).to.changeTokenBalances(
        //         token,
        //         [vault, fund, dev],
        //         [eth(2000 * -1), eth(2000), 0]
        //     )

        // })

    })


    describe("Swap", function () {

        it("token to eth", async function () {

            await token.updateTaxFee(0, 0, 0);
            await expect(vault.swapTokenToETH(token.address, eth(1000))).to.changeTokenBalances(
                token,
                [vault, fund, dev],
                [eth(1000 * -1), 0, 0]
            )

        })

        it("eth to token", async function () {

            await vault.swapETHToToken(token.address, eth(100))

        })

        it("token to token", async function () {

            await vault.swap(token.address, _weth9.address, eth(100))

        })

    })




});
