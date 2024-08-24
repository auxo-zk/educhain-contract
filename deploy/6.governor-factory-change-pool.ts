import { HardhatRuntimeEnvironment } from "hardhat/types";

module.exports = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments, network } = hre;

  const { execute, get } = deployments;
  const { deployer } = await getNamedAccounts();

  await execute(
    "GovernorFactory",
    {
      from: deployer,
      log: true,
    },
    "changeRevenuePoolFactory",
    "0xc5b09B20fb7C37048A4C58eA35615995E889d718",
    deployer
  );
};

module.exports.dependencies = [];
module.exports.tags = ["GovernorFactoryChangePool"];
