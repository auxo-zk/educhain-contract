// import { HardhatRuntimeEnvironment } from "hardhat/types";

// module.exports = async function (hre: HardhatRuntimeEnvironment) {
//   const { getNamedAccounts, deployments, network } = hre;

//   const { execute } = deployments;
//   const { deployer } = await getNamedAccounts();

//   await execute(
//     "DeNubeNFT",
//     {
//       from: deployer,
//       log: true,
//     },
//     "setRefSaleRange",
//     [0, 1, 2],
//     [refConfig[0], refConfig[1], refConfig[2]]
//   );
// };

// module.exports.dependencies = [];
// module.exports.tags = ["NFTRefConfig"];
