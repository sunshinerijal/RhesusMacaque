const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RhesusMacaqueCoin", function () {
  let RHEM, rhem, owner, dao, communityWallet, timelock, user;
  const CAP = ethers.utils.parseEther("1000000000");
  const ZERO_ADDRESS = ethers.constants.AddressZero;

  beforeEach(async function () {
    [owner, dao, communityWallet, timelock, user] = await ethers.getSigners();
    const merkleRoot = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("test"));
    RHEM = await ethers.getContractFactory("RhesusMacaqueCoin");
    rhem = await RHEM.deploy(dao.address, communityWallet.address, timelock.address, merkleRoot, dao.address);
    await rhem.deployed();
  });

  it("should initialize with correct parameters", async function () {
    expect(await rhem.name()).to.equal("Rhesus Macaque Coin");
    expect(await rhem.symbol()).to.equal("RHEM");
    expect(await rhem.totalSupply()).to.equal(CAP);
    expect(await rhem.balanceOf(timelock.address)).to.equal(CAP.mul(15).div(100));
    expect(await rhem.balanceOf(communityWallet.address)).to.equal(CAP.mul(15).div(100));
    expect(await rhem.balanceOf(dao.address)).to.equal(CAP.mul(10).div(100));
  });

  it("should allow transfers with fees", async function () {
    const amount = ethers.utils.parseEther("1000");
    await rhem.connect(owner).transfer(user.address, amount);
    const burnFee = amount.mul(5).div(1000); // 0.5%
    const devFee = amount.mul(25).div(10000); // 0.25%
    const finalAmount = amount.sub(burnFee).sub(devFee);
    expect(await rhem.balanceOf(user.address)).to.equal(finalAmount);
    expect(await rhem.balanceOf(communityWallet.address)).to.equal(CAP.mul(15).div(100).add(devFee));
    expect(await rhem.totalSupply()).to.equal(CAP.sub(burnFee));
  });

  it("should revert if non-DAO calls snapshot", async function () {
    await expect(rhem.connect(user).snapshot()).to.be.revertedWith("Not DAO");
  });
});