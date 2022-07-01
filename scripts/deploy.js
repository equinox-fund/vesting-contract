const dayjs = require("dayjs");
const localizedFormat = require("dayjs/plugin/localizedFormat");
const { ethers } = require("hardhat");
const setup = require("./setup.json");

dayjs.extend(localizedFormat);

async function main() {
  const { tokenContractAddress, startDate, durationInDays, slicePeriodInDays } =
    setup;

  const dayInSeconds = 86400;
  const _startDate = dayjs(startDate).unix();
  const _duration = durationInDays * dayInSeconds;
  const _slicePeriod = slicePeriodInDays * dayInSeconds;

  const [deployer] = await ethers.getSigners();

  // just for log info
  const firstRelease = dayjs(startDate)
    .add(slicePeriodInDays, "days")
    .format("LLLL");
  console.log("First release on ", firstRelease);

  console.log("Deploying contract with account: ", deployer.address);

  const Contract = await ethers.getContractFactory("Vesting");
  const contract = await Contract.deploy(
    tokenContractAddress,
    _startDate,
    _duration,
    _slicePeriod
  );

  await contract.deployed();
  console.log("Contract deployed to: ", contract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
