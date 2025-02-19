const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Obține balanța contului folosind provider-ul asociat
  const balance = await deployer.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "ETH");

  // Deploy ReputationToken
  const ReputationToken = await ethers.getContractFactory("ReputationToken");
  const reputationToken = await ReputationToken.deploy();
  await reputationToken.waitForDeployment();  // Așteaptă deploy-ul
  console.log("ReputationToken deployed to:", reputationToken.target);

  // Deploy ReputationSystem
  const ReputationSystem = await ethers.getContractFactory("ReputationSystem");
  const reputationSystem = await ReputationSystem.deploy();
  await reputationSystem.waitForDeployment();
  console.log("ReputationSystem deployed to:", reputationSystem.target);

  // Setează adresa ReputationToken în ReputationSystem
  const tx = await reputationSystem.setTokenAddress(reputationToken.target);
  await tx.wait();
  console.log("Token address set in ReputationSystem.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
