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
    "0xF13f328C397891dF0207eD628976fA4a2Af9d835"
  );

  console.log("nextCampaignId: ", await campaign.nextCampaignId());
  console.log("campaign state: ", await campaign.state(4));
  console.log("campaign data: ", await campaign.campaignData(4));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
