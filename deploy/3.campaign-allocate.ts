import { HardhatRuntimeEnvironment } from "hardhat/types";

module.exports = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments, network } = hre;

  const { execute, get } = deployments;
  const { deployer } = await getNamedAccounts();

  await execute(
    "Campaign",
    {
      from: deployer,
      log: true,
    },
    "allocateFunds",
    2
  );
};

module.exports.dependencies = [];
module.exports.tags = ["CampaignAllocateFund"];
