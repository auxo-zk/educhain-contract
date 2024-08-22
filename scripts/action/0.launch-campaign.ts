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

  const dateNow = Date.now() / 1000;
  const startFunding = dateNow + 2 * 24 * 60 * 60;
  const duration = 2 * 24 * 60 * 60;
  const tokenAddress = "0xd35f12eF94db3d84Bbf2a43F2537cF294C7E6717";
  const descriptionHash =
    "0x1b8f458aac55c8272fc53d29470d496009274c7e67723e8ee012856d683f1969";

  await sendTxn(
    campaign.launchCampaign(
      startFunding,
      duration,
      tokenAddress,
      descriptionHash
    ),
    ""
  );

  const nextCampaignId = await campaign.nextCampaignId();
  console.log("nextCampaignId: ", nextCampaignId);
  // console.log("campaign 0: ", await campaign.state(nextCampaignId));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
