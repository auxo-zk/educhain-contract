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
    "0xfa8E1595Df8e7c1952686e153B6c16B1d582B59f"
  );

  const governor = await contractAt(
    "Governor",
    "0xcE3312EC7Dd4A379903b8c8CD3cC965395562013"
  );

  // 0xcE3312EC7Dd4A379903b8c8CD3cC965395562013

  let returnValue = await governorFactory.getAllToken(
    "0xcE3312EC7Dd4A379903b8c8CD3cC965395562013",
    "0xe3C66D29ed3260f2b9DAc9f7037Fc728DC793C70"
  );

  console.log("return value: ", returnValue);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
