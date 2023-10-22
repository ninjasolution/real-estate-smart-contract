const fs = require('fs');
require("@nomicfoundation/hardhat-toolbox");
require("@onmychain/hardhat-uniswap-v2-deploy-plugin");
// Any file that has require('dotenv').config() statement 
// will automatically load any variables in the root's .env file.
require('dotenv').config();

const PRIVATE_KEY = process.env.PRIVATE_KEY
const etherscanKey = process.env.BSSCAN_KEY
const infraKey = process.env.INFRA_KEY

function getRemappings() {
  return fs
    .readFileSync('remappings.txt', 'utf8')
    .split('\n')
    .filter(Boolean)
    .map((line) => line.trim().split('='));
}

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    mainnet: {
      url: `https://mainnet.infura.io/v3/${infraKey}`,
      accounts: [PRIVATE_KEY],
      //gasPrice: 120 * 1000000000,
      chainId: 1,
    },
    bsc: {
      url: "https://bsc-dataseed.binance.org/",
      accounts: [PRIVATE_KEY]
    },
    hardhat: {
      allowUnlimitedContractSize: true,
      chainId: 31337,
      gasPrice: 20000000000,
      gas: 6000000,
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${infraKey}`,
      accounts: [PRIVATE_KEY],
      // gas: 2100000,
      // gasPrice: 8000000000
    },
    localhost: {
      live: false,
      saveDeployments: true,
      tags: ["local"],
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000000,
          },
          viaIR: true
        },
      },
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000000,
            details: {
              yul: true,
              yulDetails: {
                stackAllocation: true,
                optimizerSteps: "dhfoDgvulfnTUtnIf"
              }
            }
          },
          viaIR: true
        },
      },]
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 400000000
  },
  etherscan: {
    apiKey: etherscanKey,
  },
  preprocess: {
    eachLine: (hre) => ({
      transform: (line) => {
        if (line.match(/^\s*import /i)) {
          getRemappings().forEach(([find, replace]) => {
            if (line.match(find)) {
              line = line.replace(find, replace);
            }
          });
        }
        return line;
      },
    }),
  },
}