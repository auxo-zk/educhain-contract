import { HardhatRuntimeEnvironment } from "hardhat/types";

module.exports = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments } = hre;

  const { deploy, get } = deployments;
  const { deployer } = await getNamedAccounts();
  const campaign = await get("Campaign");

  await deploy("Helper", {
    from: deployer,
    proxy: {
      proxyContract: "OpenZeppelinTransparentProxy",
      execute: {
        init: {
          methodName: "initialize",
          args: [deployer, campaign.address],
        },
      },
    },
    log: true,
  });
};

module.exports.dependencies = [];
module.exports.tags = ["Campaign"];
