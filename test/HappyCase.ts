import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre, { ethers } from "hardhat";

type FundingConfig = { fundingDelay: number; fundingPeriod: number };
type VotingConfig = {
  votingDelay: number;
  votingPeriod: number;
  timelockPeriod: number;
  queuingPeriod: number;
};

const random32Bytes =
  "0xb9dd80b0314d13e12c9c1e0ce37bde8586465458a7376eb275c5ec7ef43369c9";

describe("", function () {
  async function deploy() {
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
    const ONE_DAY_IN_SECS = 24 * 60 * 60;
    const ONE_GWEI = 1_000_000_000;

    let accounts = await hre.ethers.getSigners();
    const founder = accounts[0];
    accounts = accounts.slice(1);
    const fundingConfig: FundingConfig = {
      fundingDelay: 100,
      fundingPeriod: 100,
    };
    const votingConfig: VotingConfig = {
      votingDelay: 100,
      votingPeriod: 100,
      timelockPeriod: 100,
      queuingPeriod: 100,
    };
    const Campaign = await hre.ethers.getContractFactory("Campaign");
    const campaign = await Campaign.deploy(
      // fundingConfig.fundingDelay,
      // fundingConfig.fundingPeriod,
      votingConfig.votingDelay,
      votingConfig.votingPeriod,
      votingConfig.timelockPeriod,
      votingConfig.queuingPeriod
    );
    const governorFactoryAddress = await campaign.governorFactory();
    const governorFactory = await hre.ethers.getContractAt(
      "GovernorFactory",
      governorFactoryAddress
    );

    console.log("Campaign ", await campaign.getAddress());
    console.log("GovernorFactory ", await governorFactory.getAddress());

    return {
      founder,
      accounts,
      campaign,
      governorFactory,
      fundingConfig,
      votingConfig,
    };
  }

  async function timestamp() {
    const blockNumber = await hre.ethers.provider.getBlockNumber();
    const block = await hre.ethers.provider.getBlock(blockNumber);
    return block?.timestamp;
  }

  async function moveTimestamp(seconds: number) {
    console.log(`Skipping ${seconds} seconds...`);
    console.log("Timestamp before:", await timestamp());
    await hre.ethers.provider.send("evm_increaseTime", [seconds]);
    await hre.ethers.provider.send("evm_mine", []);
    console.log("Timestamp after:", await timestamp());
  }

  async function mineBlock(blocks: number) {
    const before = await hre.ethers.provider.getBlockNumber();
    console.log("BlockNumber before:", before);
    for (let i = 0; i < blocks; i++) {
      await hre.ethers.provider.send("evm_mine", []);
    }
    console.log("Mining blocks...");
    const after = await hre.ethers.provider.getBlockNumber();
    console.log("BlockNumber after:", after);
  }

  describe("Deployment", function () {
    it("1", async function () {
      const {
        founder,
        accounts,
        campaign,
        governorFactory,
        fundingConfig,
        votingConfig,
      } = await loadFixture(deploy);

      const governors = [];
      const tokens = [];

      // 0
      await governorFactory.createGovernor(
        "Course 1",
        "Course 1",
        "c1",
        random32Bytes
      );
      expect(await governorFactory.nextGovernorId()).to.be.equal(1);
      let governorId = 0;
      let governorAddress = await governorFactory.governor(governorId);
      let governor = await hre.ethers.getContractAt(
        "Governor",
        governorAddress
      );
      let tokenAddress = await governor.token();
      let token = await hre.ethers.getContractAt("ERC721Votes", tokenAddress);
      governors.push(governor);
      tokens.push(token);

      // 1
      await governorFactory.createGovernor(
        "Course 2",
        "Course 2",
        "c2",
        random32Bytes
      );
      expect(await governorFactory.nextGovernorId()).to.be.equal(2);
      governorId = 1;
      governorAddress = await governorFactory.governor(governorId);
      governor = await hre.ethers.getContractAt("Governor", governorAddress);
      tokenAddress = await governor.token();
      token = await hre.ethers.getContractAt("ERC721Votes", tokenAddress);
      governors.push(governor);
      tokens.push(token);

      // 2
      await governorFactory.createGovernor(
        "Course 3",
        "Course 3",
        "c3",
        random32Bytes
      );
      expect(await governorFactory.nextGovernorId()).to.be.equal(3);
      governorId = 2;
      governorAddress = await governorFactory.governor(governorId);
      governor = await hre.ethers.getContractAt("Governor", governorAddress);
      tokenAddress = await governor.token();
      token = await hre.ethers.getContractAt("ERC721Votes", tokenAddress);
      governors.push(governor);
      tokens.push(token);

      await campaign.launchCampaign(
        fundingConfig.fundingDelay,
        fundingConfig.fundingPeriod,
        random32Bytes
      );
      expect(await campaign.nextCampaignId()).to.be.equal(2);
      const campaignId = 1;
      expect(await campaign.state(campaignId)).to.be.equal(0);

      for (let i = 0; i < governors.length; i++) {
        let governor = governors[i];
        await governor.joinCampaign();

        const data = await campaign.courseData(
          campaignId,
          await governor.governorId()
        );
        expect(data[0]).to.be.equal(await governor.getAddress());
        expect(data[1]).to.be.equal(0n);
      }

      // await moveTimestamp(fundingConfig.fundingDelay + 1);
      await mineBlock(100);
      expect(await campaign.state(campaignId)).to.be.equal(1);

      const fundAmounts = [
        ethers.parseUnits("1", "ether"),
        ethers.parseUnits("2", "ether"),
        ethers.parseUnits("1.1", "ether"),
        ethers.parseUnits("0.5", "ether"),
        ethers.parseUnits("0.6", "ether"),
        ethers.parseUnits("0.7", "ether"),
        ethers.parseUnits("1", "ether"),
        ethers.parseUnits("1.3", "ether"),
        ethers.parseUnits("2.1", "ether"),
        ethers.parseUnits("0.9", "ether"),
      ];
      const choices = [1, 0, 2, 1, 2, 2, 0, 0, 1, 0];
      const result = [0n, 0n, 0n];
      let totalFunded = 0n;
      const account = accounts[1];
      for (let i = 0; i < fundAmounts.length; i++) {
        await campaign
          .connect(account)
          .fund(choices[i], { value: fundAmounts[i] });
        totalFunded += fundAmounts[i];
        result[choices[i]] += fundAmounts[i];
      }
      const campaignData = await campaign.campaignData(campaignId);
      expect(campaignData[0]).to.be.equal(totalFunded);
      expect(
        await hre.ethers.provider.getBalance(await campaign.getAddress())
      ).to.be.equal(totalFunded);

      await mineBlock(100);
      expect(await campaign.state(campaignId)).to.be.equal(2);

      await campaign.allocateFunds();
      for (let i = 0; i < governors.length; i++) {
        const governor = governors[i];
        const address = await governor.getAddress();
        expect(await hre.ethers.provider.getBalance(address)).to.be.equal(
          result[i]
        );
        expect(await governor.totalFunded()).to.be.equal(result[i]);
        // console.log(await governors[i].nextTokenId());
      }
      expect(await campaign.state(campaignId)).to.be.equal(3);

      const revenuePoolFactory = await hre.ethers.getContractAt(
        "RevenuePoolFactory",
        await governors[0].revenuePoolFactory()
      );

      await revenuePoolFactory.createPool({
        value: ethers.parseUnits("2", "ether"),
      });
      
      const poolAddress = await revenuePoolFactory.pool(0);
      const pool = await hre.ethers.getContractAt("RevenuePool", poolAddress);
      // console.log(await hre.ethers.provider.getBalance(poolAddress));
      const tokenIds = [0, 1, 2, 3];
      // const values = [
      //     ethers.parseUnits("2", "ether"),
      //     ethers.parseUnits("1", "ether"),
      //     ethers.parseUnits("1.3", "ether"),
      //     ethers.parseUnits("0.9", "ether"),
      // ];
      let totalAmount = 0n;
      for (let i = 0; i < tokenIds.length; i++) {
        const balanceBefore = await hre.ethers.provider.getBalance(
          account.address
        );
        await pool.connect(account).claim(tokenIds[i]);
        const balanceAfter = await hre.ethers.provider.getBalance(
          account.address
        );
        const amount = balanceAfter - balanceBefore;
        totalAmount += amount;
      }
      // console.log(totalAmount);

      governorId = 0;
      governorAddress = await governorFactory.governor(governorId);
      governor = await hre.ethers.getContractAt("Governor", governorAddress);
      await governor.propose(
        [accounts[1].address],
        ["0x00"],
        ["0x00"],
        random32Bytes
      );
      const proposalIndex = 0;
      const proposalId = await governor.proposalIds(proposalIndex);
      expect(await governor.state(proposalId)).to.be.equal(0);
      await mineBlock(101);
      expect(await governor.state(proposalId)).to.be.equal(1);

      await governor.connect(account).castVote(proposalId, tokenIds[0], 0);
      await governor.connect(account).castVote(proposalId, tokenIds[1], 1);
      await governor.connect(account).castVote(proposalId, tokenIds[2], 2);
      await governor.connect(account).castVote(proposalId, tokenIds[3], 2);

      // console.log(await governor.proposalVotes(proposalId));
      await mineBlock(100);
      // console.log(await governor.state(proposalId));
      expect(await governor.state(proposalId)).to.be.equal(3);
      // console.log(await governor.proposalCounter());
    });
  });
});
