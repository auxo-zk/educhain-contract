import {
  deployProxyContract,
  deployContract,
  sendTxn,
  contractAt,
} from "./shared/helpers";
import hre, { ethers } from "hardhat";

async function main() {
  const accounts = await hre.ethers.getSigners();

  console.log("account: ", accounts[0].address);

  // const hireNFTContract = await contractAt(
  //   "HireGateWay",
  //   "0xa8Ec67724Ec21757eF0F84D0dEe1403D051F1609"
  // );

  const usdt = await contractAt(
    "TokenToken",
    "0xd35f12eF94db3d84Bbf2a43F2537cF294C7E6717"
  );

  // temp
  // console.log("send eth");
  // await accounts[0].sendTransaction({
  //   to: accounts[2].address,
  //   value: ethers.parseEther("0.1"),
  // });
  // console.log("send eth: done");
  // await usdt.transfer(accounts[2].address, ethers.parseEther("1000000000"));

  // await accounts[0].sendTransaction({
  //   to: "0xe3C66D29ed3260f2b9DAc9f7037Fc728DC793C70",
  //   value: ethers.parseEther("0.1"),
  // });
  console.log("send eth: done");
  await usdt.transfer(
    "0xe3C66D29ed3260f2b9DAc9f7037Fc728DC793C70",
    ethers.parseEther("1000000000")
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
