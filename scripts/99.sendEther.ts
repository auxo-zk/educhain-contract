import {
  deployProxyContract,
  deployContract,
  sendTxn,
  contractAt,
} from "./shared/helpers";
import hre, { ethers } from "hardhat";

async function main() {
  const accounts = await hre.ethers.getSigners();

  const hireNFTContract = await contractAt(
    "HireGateWay",
    "0xa8Ec67724Ec21757eF0F84D0dEe1403D051F1609"
  );

  const usdt = await contractAt(
    "TetherToken",
    "0x8E1B890a0519A206A562Dd66B7B2B5e338B43bf2"
  );

  // temp
  console.log("send eth");
  await accounts[0].sendTransaction({
    to: accounts[2].address,
    value: ethers.parseEther("0.1"),
  });
  console.log("send eth: done");
  await usdt.transfer(accounts[2].address, ethers.parseEther("1000000000"));

  await accounts[0].sendTransaction({
    to: accounts[3].address,
    value: ethers.parseEther("0.1"),
  });
  console.log("send eth: done");
  await usdt.transfer(accounts[3].address, ethers.parseEther("1000000000"));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
