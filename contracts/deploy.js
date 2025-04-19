const hre = require("hardhat");

async function main() {
  const [deployer, dao, devWallet, communityWallet, timelock] = await hre.ethers.getSigners();
  const merkleRoot = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("test"));

  // Deploy RHEM Token
  const RHEM = await hre.ethers.getContractFactory("RhesusMacaqueCoin");
  const rhem = await RHEM.deploy(dao.address, communityWallet.address, timelock.address, merkleRoot, dao.address);
  await rhem.deployed();
  console.log("RHEM deployed to:", rhem.address);

  // Deploy NFTMarketplaceStorage (for NFTMarketplaceCore)
  const Storage = await hre.ethers.getContractFactory("NFTMarketplaceStorage");
  const storage = await Storage.deploy();
  await storage.deployed();

  // Deploy NFTMarketplaceEvents
  const Events = await hre.ethers.getContractFactory("NFTMarketplaceEvents");
  const events = await Events.deploy();
  await events.deployed();

  // Deploy NFTMarketplaceCore
  const Marketplace = await hre.ethers.getContractFactory("NFTMarketplaceCore", {
    libraries: {
      NFTMarketplaceStorage: storage.address,
      NFTMarketplaceEvents: events.address,
    },
  });
  const marketplace = await Marketplace.deploy();
  await marketplace.deployed();
  await marketplace.initializeMarketplace(dao.address, devWallet.address, rhem.address, hre.ethers.constants.AddressZero);
  console.log("NFTMarketplaceCore deployed to:", marketplace.address);

  // Deploy NFTStaking
  const Staking = await hre.ethers.getContractFactory("NFTStaking");
  const staking = await Staking.deploy(marketplace.address, rhem.address, dao.address, hre.ethers.utils.parseEther("0.01"), 86400);
  await staking.deployed();
  console.log("NFTStaking deployed to:", staking.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});