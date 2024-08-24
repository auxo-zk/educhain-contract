import { HardhatRuntimeEnvironment } from "hardhat/types";

module.exports = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments, network } = hre;

  const { execute, get } = deployments;
  const { deployer } = await getNamedAccounts();
  const revenuePoolFactoryCreator = await get("RevenuePoolFactoryCreator");
  console.log("revenuePoolFactoryCreator: ", revenuePoolFactoryCreator.address);

  await execute(
    "GovernorFactory",
    {
      from: deployer,
      log: true,
    },
    "changeRevenuePoolFactoryCreator",
    revenuePoolFactoryCreator.address
  );
};

module.exports.dependencies = [];
module.exports.tags = ["GovernorFactorySetPoolCreator"];
