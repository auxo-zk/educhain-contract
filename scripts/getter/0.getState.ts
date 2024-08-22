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
    "0x17049dC67055b8D8d762eC5D8c331077e44eBB83"
  );

  console.log("nextCampaignId: ", await campaign.nextCampaignId());
  console.log("campaign 0: ", await campaign.state(1));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
