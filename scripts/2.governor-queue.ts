import {
  deployProxyContract,
  deployContract,
  sendTxn,
  contractAt,
} from "./shared/helpers";
import hre, { ethers } from "hardhat";

async function main() {
  const accounts = await hre.ethers.getSigners();

  const governor = await contractAt(
    "Governor",
    "0x1E2a2c5cF339468A70Dbc18b3B4eEf664d5E1B22"
  );

  await sendTxn(
    governor.queue(
      61377833908042401742780487942686429224010466569238862502524632706640640691312n
    ),
    "governor.queue"
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
