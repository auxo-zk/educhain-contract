import {
  deployProxyContract,
  deployContract,
  sendTxn,
  contractAt,
} from "../shared/helpers";
import hre, { ethers } from "hardhat";

async function main() {
  const accounts = await hre.ethers.getSigners();

  const campaign = await contractAt(
    "Campaign",
    "0x07c2A3893b5c30A32015D8D7f869749b97CEc821"
  );

  let returnValue = await campaign.ableToVestAmount(
    1,
    "0x63Bf9c7E10a0225E10800e837e00Ea7Cb3fAAe16"
  );

  console.log("return value: ", returnValue);

  returnValue = await campaign.fundedAmounts(
    1,
    "0x63Bf9c7E10a0225E10800e837e00Ea7Cb3fAAe16"
  );
  console.log("return value: ", returnValue);

  returnValue = await campaign.totalVesteds(
    1,
    "0x63Bf9c7E10a0225E10800e837e00Ea7Cb3fAAe16"
  );
  console.log("return value: ", returnValue);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
