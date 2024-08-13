import {
  Provider,
  TransactionResponse,
  TransactionReceipt,
} from "@ethersproject/providers";
import { Wallet, MaxUint256 } from "ethers";
import { BigNumber } from "@ethersproject/bignumber";

function bigNumberify(n: any): BigNumber {
  return BigNumber.from(n);
}

function expandDecimals(n: any, decimals: number): BigNumber {
  return bigNumberify(n).mul(bigNumberify(10).pow(decimals));
}

async function gasUsed(
  provider: Provider,
  tx: TransactionResponse
): Promise<BigNumber> {
  const receipt: TransactionReceipt = await provider.getTransactionReceipt(
    tx.hash
  );
  return receipt.gasUsed;
}

async function getNetworkFee(
  provider: Provider,
  tx: TransactionResponse
): Promise<BigNumber> {
  const gas: BigNumber = await gasUsed(provider, tx);
  return gas.mul(tx.gasPrice!);
}

async function reportGasUsed(
  provider: Provider,
  tx: TransactionResponse,
  label: string
): Promise<BigNumber> {
  const { gasUsed } = await provider.getTransactionReceipt(tx.hash);
  console.info(label, gasUsed.toString());
  return gasUsed;
}

async function getBlockTime(provider: Provider): Promise<number> {
  const blockNumber = await provider.getBlockNumber();
  const block = await provider.getBlock(blockNumber);
  return block.timestamp;
}

async function getTxnBalances(
  provider: Provider,
  user: Wallet,
  txn: () => Promise<TransactionResponse>,
  callback: (balance0: BigNumber, balance1: BigNumber, fee: BigNumber) => void
): Promise<void> {
  const balance0 = await provider.getBalance(user.address);
  const tx = await txn();
  const fee = await getNetworkFee(provider, tx);
  const balance1 = await provider.getBalance(user.address);
  callback(balance0, balance1, fee);
}

module.exports = {
  MaxUint256,
  bigNumberify,
  expandDecimals,
  gasUsed,
  getNetworkFee,
  reportGasUsed,
  getBlockTime,
  getTxnBalances,
  print,
};
