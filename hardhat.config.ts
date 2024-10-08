import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-contract-sizer";
import "hardhat-abi-exporter";
import "hardhat-deploy";
import "hardhat-deploy-ethers";

import "dotenv/config";

var accounts;
const mnemonic: string | undefined = process.env.MNEMONIC;

const keys: any | undefined = process.env.KEYS?.split(" ").map((key) => ({
  privateKey: key,
  balance: "10000000000000000000000",
}));

if (process.env.MNEMONIC) accounts = { mnemonic };
else if (process.env.KEYS) accounts = keys;

const chainIds = {
  hardhat: 31337,
  eth: 1,
  goerli: 5,
  educhain: 656476,
  sepolia: 11155111,
  "mantle-testnet": 5001,
  "bnb-testnet": 97,
};

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  namedAccounts: {
    deployer: 0,
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      chainId: chainIds.hardhat,
      blockGasLimit: 10000000000,
      accounts: accounts,
    },
    localhost: {
      accounts: process.env.KEYS?.split(" "),
      chainId: 31337,
      blockGasLimit: 10000000000,
      allowUnlimitedContractSize: true,
      timeout: 1000000,
    },
    educhain: {
      chainId: chainIds.educhain,
      loggingEnabled: true,
      saveDeployments: true,
      url: "https://open-campus-codex-sepolia.drpc.org",
      accounts: [process.env.acc1!],
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      // {
      //   version: "0.8.12",
      //   settings: {
      //     optimizer: {
      //       enabled: true,
      //       runs: 200,
      //     },
      //   },
      // },
    ],
  },
  gasReporter: {
    currency: "ETH",
    enabled: true,
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  abiExporter: [
    {
      path: "./abi/json",
      format: "json",
      runOnCompile: true,
    },
  ],
};

export default config;
