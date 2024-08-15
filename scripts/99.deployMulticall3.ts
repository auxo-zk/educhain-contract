import { deployProxyContract, deployContract, sendTxn } from "./shared/helpers";
import hre, { ethers } from "hardhat";

async function main() {
  const accounts = await hre.ethers.getSigners();
  const Multicall3 = await deployContract("Multicall3", []);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
