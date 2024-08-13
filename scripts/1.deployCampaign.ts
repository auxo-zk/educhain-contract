import { deployProxyContract, deployContract, sendTxn } from "./shared/helpers";
import hre, { ethers } from "hardhat";

type VotingConfig = {
  timelockPeriod: bigint;
  queuingPeriod: bigint;
};

async function main() {
  const accounts = await hre.ethers.getSigners();

  const votingConfig: VotingConfig = {
    timelockPeriod: 0n,
    queuingPeriod: 10000000000000000n,
  };

  const campaign = await deployContract("Campaign", [
    votingConfig.timelockPeriod,
    votingConfig.queuingPeriod,
  ]);

  console.log("Governor factory address: ", await campaign.governorFactory());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
