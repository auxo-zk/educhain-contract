import { HardhatRuntimeEnvironment } from "hardhat/types";

module.exports = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments } = hre;

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("RevenuePoolFactoryCreator", {
    from: deployer,
    args: [],
    log: true,
  });
};

module.exports.dependencies = [];
module.exports.tags = ["RevenuePoolFactoryCreator"];
