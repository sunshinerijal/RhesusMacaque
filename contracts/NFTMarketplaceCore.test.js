const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarketplaceCore", function () {
  let NFTMarketplace, marketplace, RHEM, rhem, owner, dao, devWallet, user;
  const listingFee = ethers.utils.parseEther("1");
  const saleFee = 75; // 0.75%

  beforeEach(async function () {
    [owner, dao, devWallet, user] = await ethers.getSigners();
    RHEM = await ethers.getContractFactory("RhesusMacaqueCoin");
    const merkleRoot = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("test"));
    rhem = await RHEM.deploy(dao.address, devWallet.address, owner.address, merkleRoot, dao.address);
    await rhem.deployed();

    NFTMarketplace = await ethers.getContractFactory("NFTMarketplaceCore");
    marketplace = await NFTMarketplace.deploy();
    await marketplace.initializeMarketplace(dao.address, devWallet.address, rhem.address, ethers.constants.AddressZero);

    await rhem.connect(owner).transfer(user.address, ethers.utils.parseEther("1000"));
  });

  it("should mint NFT by DAO", async function () {
    const tokenURI = "ipfs://test";
    await expect(marketplace.connect(dao).mint(tokenURI))
      .to.emit(marketplace, "Minted")
      .withArgs(dao.address, 1, tokenURI);
    expect(await marketplace.ownerOf(1)).to.equal(dao.address);
  });

  it("should list and purchase NFT", async function () {
    const tokenURI = "ipfs://test";
    await marketplace.connect(dao).mint(tokenURI);
    const price = ethers.utils.parseEther("100");
    await rhem.connect(user).approve(marketplace.address, price.add(listingFee));
    await marketplace.connect(dao).listNFT(1, price);
    await expect(marketplace.connect(user).purchaseNFT(1))
      .to.emit(marketplace, "Purchased")
      .withArgs(user.address, 1, price);
    expect(await marketplace.ownerOf(1)).to.equal(user.address);
  });

  it("should revert if non-owner lists NFT", async function () {
    await marketplace.connect(dao).mint("ipfs://test");
    await expect(marketplace.connect(user).listNFT(1, ethers.utils.parseEther("100")))
      .to.be.revertedWith("Not token owner");
  });
});