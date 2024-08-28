import {
  deployProxyContract,
  deployContract,
  sendTxn,
  contractAt,
} from "../shared/helpers";
import hre, { ethers } from "hardhat";

async function main() {
  const accounts = await hre.ethers.getSigners();

  const governorFactory = await contractAt(
    "GovernorFactory",
    "0x7F5BBCc804A94c4d450871612993cBE480Fe0E22"
  );

  let returnValue = await governorFactory.lastProposal(
    "0x1E2a2c5cF339468A70Dbc18b3B4eEf664d5E1B22"
  );

  console.log("return value: ", returnValue);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
