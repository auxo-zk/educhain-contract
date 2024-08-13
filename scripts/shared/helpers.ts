import { ethers, upgrades } from "hardhat";
import { DeployProxyOptions } from "@openzeppelin/hardhat-upgrades/dist/utils";

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function sendTxn(txnPromise: Promise<any>, label?: string): Promise<any> {
  const txn = await txnPromise;
  if (label) {
    console.info(`Sending ${label}...`);
  }
  await txn.wait();
  if (label) {
    console.info(`... Sent! ${txn.hash}`);
  }
  // await sleep(500)
  return txn;
}

async function callWithRetries<T>(
  func: (...args: any[]) => Promise<T>,
  args: any[],
  retriesCount: number = 3
): Promise<T> {
  let i = 0;
  while (true) {
    i++;
    try {
      return await func(...args);
    } catch (ex) {
      if (i === retriesCount) {
        console.error("call failed %s times. throwing error", retriesCount);
        throw ex;
      }
      console.error("call i=%s failed. retrying....", i);
      console.error(ex);
    }
  }
}

interface DeployOptions {
  gasLimit?: number;
  gasPrice?: number;
  value?: number;
}

async function deployContract(
  name: string,
  args: any[],
  label?: string | DeployOptions,
  options?: DeployOptions
): Promise<any> {
  if (!options && typeof label === "object") {
    options = label as DeployOptions;
    label = undefined;
  }
  let info = name;
  if (label) {
    info = name + ": " + label;
  }
  const contractFactory = await ethers.getContractFactory(name);
  let contract;
  if (options) {
    contract = await contractFactory.deploy(...args, options);
  } else {
    contract = await contractFactory.deploy(...args);
  }
  // const argStr = args.map((i) => `"${i}"`).join(" ")
  console.info(`Deploying ${info} = ${await contract.getAddress()}`);
  let tx = await contract.waitForDeployment();

  if (label === undefined)
    console.info(
      `Completed ${info} at txHash: ${tx.deploymentTransaction()?.hash}`
    );
  else
    console.info(
      `Completed ${label} at txHash: ${tx.deploymentTransaction()?.hash}`
    );
  console.info(`========================`);
  return contract;
}

async function deployProxyContract(
  name: string,
  args: any[],
  label?: string | DeployProxyOptions,
  options?: DeployProxyOptions
): Promise<any> {
  const contractFactory = await ethers.getContractFactory(name);
  let contract;
  if (!options && typeof label === "object") {
    options = label as DeployProxyOptions;
    label = undefined;
  }

  let info = name;
  if (label) {
    info = name + ": " + label;
  }
  if (options) {
    contract = await upgrades.deployProxy(contractFactory, args, options);
  } else {
    contract = await upgrades.deployProxy(contractFactory, args);
  }
  // const argStr = args.map((i) => `"${i}"`).join(" ")
  console.info(`Deploying ${info} Proxy = ${await contract.getAddress()}`);

  let tx = await contract.waitForDeployment();

  if (label === undefined)
    console.info(
      `Completed ${info} at txHash: ${tx.deploymentTransaction()?.hash}`
    );
  else
    console.info(
      `Completed ${label} at txHash: ${tx.deploymentTransaction()?.hash}`
    );
  let addressInfo = {
    [name]: await contract.getAddress(),
  };
  // if ((await ethers.provider.getNetwork()).name != "hardhat") await sleep(1000);
  console.info(`========================`);
  return contract;
}

async function upgradeContractProxy(
  name: string,
  address: string
): Promise<any> {
  const contractFactory = await ethers.getContractFactory(name);

  let info = name;
  let upgradeContract;
  if (contractFactory) {
    upgradeContract = await upgrades.upgradeProxy(address, contractFactory);
    console.info(
      `Upgrade ${info} Proxy SUCCESS = ${await upgradeContract.getAddress()}`
    );
  } else {
    console.info(`Upgrade ${info} Proxy FAIL since: contractFactory = null`);
  }
  console.info(`========================`);
  return contractFactory.attach(address);
}

export { deployProxyContract, upgradeContractProxy };

async function contractAt(
  name: string,
  address: string,
  provider?: any
): Promise<any> {
  let contractFactory = await ethers.getContractFactory(name);
  if (provider) {
    contractFactory = contractFactory.connect(provider);
  }
  return contractFactory.attach(address);
}

export { sendTxn, deployContract, contractAt, callWithRetries };
