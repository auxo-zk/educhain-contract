import { HardhatRuntimeEnvironment } from "hardhat/types";

module.exports = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments, network } = hre;

  const { execute, get } = deployments;
  const { deployer } = await getNamedAccounts();

  const governorFactory = await get("GovernorFactory");

  await execute(
    "Campaign",
    {
      from: deployer,
      log: true,
    },
    "setGovernorFactory",
    governorFactory.address
  );
};

module.exports.dependencies = [];
module.exports.tags = ["CampaignConfig"];
