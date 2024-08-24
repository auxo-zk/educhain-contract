import {
  deployProxyContract,
  deployContract,
  sendTxn,
  contractAt,
} from "../shared/helpers";
import hre, { ethers } from "hardhat";

async function main() {
  const accounts = await hre.ethers.getSigners();

  const governor = await contractAt(
    "Governor",
    "0xcE3312EC7Dd4A379903b8c8CD3cC965395562013"
  );

  let tokenAddress = await governor.token();
  console.log("token: ", tokenAddress);

  const ERC721Votes = await contractAt("ERC721Votes", tokenAddress);

  let balanceOf = await ERC721Votes.balanceOf(
    "0xe3C66D29ed3260f2b9DAc9f7037Fc728DC793C70"
  );

  console.log("balanceOf: ", balanceOf);

  let votingPower = await ERC721Votes.getVotingPower(0);
  console.log("voting power: ", votingPower);

  votingPower = await ERC721Votes.getVotingPower(1);
  console.log("voting power: ", votingPower);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
