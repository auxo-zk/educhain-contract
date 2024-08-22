import { HardhatRuntimeEnvironment } from "hardhat/types";

module.exports = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments, network } = hre;

  const { deploy, get } = deployments;
  const { deployer } = await getNamedAccounts();

  const campaign = await get("Campaign");

  await deploy("GovernorFactory", {
    from: deployer,
    proxy: {
      proxyContract: "OpenZeppelinTransparentProxy",
      execute: {
        init: {
          methodName: "initialize",
          args: [
            deployer,
            campaign.address, //refRevenue
            0n,
            10000000000000000n,
          ],
        },
      },
    },
    log: true,
  });
};

module.exports.dependencies = [];
module.exports.tags = ["GovernorFactory"];
