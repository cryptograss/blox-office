import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";
import "@nomicfoundation/hardhat-ignition";
import dotenv from "dotenv";
import "@nomicfoundation/hardhat-chai-matchers";


dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      { version: "0.8.20" },
      { version: "0.8.28" }
    ]
  },
  networks: {
    hardhat: {
      chainId: 31337
    },
    polygon: {
      url: process.env.POLYGON_RPC_URL ?? "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 137
    },
    "polygon-amoy": {
      url: process.env.POLYGON_AMOY_RPC_URL ?? "",
      accounts: process.env.PRIVATE_KEY ? [`0x${process.env.PRIVATE_KEY}`] : [],
      chainId: 80002,
      gas: "auto",
      gasPrice: "auto",
      httpHeaders: {
        "Content-Type": "application/json"
      }
    },
    optimism: {
      url: process.env.OPTIMISM_RPC_URL ?? "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 10
    },
    "optimism-goerli": {
      url: process.env.OPTIMISM_GOERLI_RPC_URL ?? "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 420
    }
  },
  etherscan: {
    apiKey: {
      polygon: process.env.POLYGONSCAN_API_KEY ?? "",
      polygonMumbai: process.env.POLYGONSCAN_API_KEY ?? "",
      optimisticEthereum: process.env.OPTIMISM_ETHERSCAN_API_KEY ?? ""
    }
  },
  paths: {
    sources: "./src/contracts",
    tests: "./tests",
    cache: "./cache",
    artifacts: "./artifacts"
  }
};

export default config;