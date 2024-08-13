import { deployProxyContract, deployContract, sendTxn } from "./shared/helpers";
import hre, { ethers } from "hardhat";

async function main() {
  const accounts = await hre.ethers.getSigners();
  const TokenToken = await deployContract("TokenToken", ["USDT", "USDT"]);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
