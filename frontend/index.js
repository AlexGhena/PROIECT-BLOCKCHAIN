window.addEventListener("load", async () => {
    // Verificam daca MetaMask este disponibil
    if (typeof window.ethereum === "undefined") {
      alert("Te rog instaleaza MetaMask!");
      return;
    }
  
    // Cream un provider pentru browser folosind MetaMask (ethers v6)
    const provider = new ethers.BrowserProvider(window.ethereum);
    let signer, userAddress;
  
    const connectButton = document.getElementById("connectButton");
    const accountInfo = document.getElementById("accountInfo");
    const balanceInfo = document.getElementById("balanceInfo");
    const reputationResult = document.getElementById("reputationResult");
    const feedbackResult = document.getElementById("feedbackResult");
  
    // Functie pentru butonul de conectare
    connectButton.addEventListener("click", async () => {
      try {
        // Cere acces la conturile din MetaMask
        await provider.send("eth_requestAccounts", []);
        signer = await provider.getSigner();
        userAddress = await signer.getAddress();
        accountInfo.innerText = `Cont conectat: ${userAddress}`;
  
        // Obtine si afiseaza balanta contului
        const balance = await provider.getBalance(userAddress);
        balanceInfo.innerText = `Balanta: ${ethers.formatEther(balance)} ETH`;
  
        // Definim ABI-ul minim necesar pentru contractul ReputationSystem
        const reputationSystemABI = [
          "function getReputation(address freelancer) external view returns (uint256)",
          "function addFeedback(address freelancer, uint256 points) external payable"
        ];
  
        // Adresa contractului ReputationSystem - inlocuieste cu adresa din Hardhat
        const reputationSystemAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
  
        // Cream instanta contractului
        window.reputationContract = new ethers.Contract(
          reputationSystemAddress,
          reputationSystemABI,
          signer
        );
      } catch (error) {
        console.error("Eroare la conectare:", error);
      }
    });
  
    // Buton pentru obtinerea reputatiei
    document
      .getElementById("getReputationButton")
      .addEventListener("click", async () => {
        if (!window.reputationContract) {
          reputationResult.innerText = "Conecteaza-te la MetaMask mai intai!";
          return;
        }
        const freelancerAddress = document.getElementById("freelancerAddress").value;
        try {
          const rep = await window.reputationContract.getReputation(freelancerAddress);
          reputationResult.innerText = `Reputatie: ${rep.toString()}`;
        } catch (error) {
          reputationResult.innerText = `Eroare: ${error.message}`;
        }
      });
  
    // Buton pentru a trimite feedback
    document
      .getElementById("provideFeedbackButton")
      .addEventListener("click", async () => {
        if (!window.reputationContract) {
          feedbackResult.innerText = "Conecteaza-te la MetaMask mai intai!";
          return;
        }
        const freelancerAddress = document.getElementById("feedbackFreelancerAddress").value;
        const points = document.getElementById("points").value;
        const ethValue = document.getElementById("ethValue").value;
        try {
          // Trimite feedback (min. 0.01 ETH)
          const tx = await window.reputationContract.addFeedback(freelancerAddress, points, {
            value: ethers.parseEther(ethValue),
          });
          feedbackResult.innerText = `Tranzactie trimisa: ${tx.hash}`;
          const receipt = await tx.wait();
          feedbackResult.innerText += `\nConfirmata in blocul ${receipt.blockNumber}`;
        } catch (error) {
          feedbackResult.innerText = `Eroare: ${error.message}`;
        }
      });
  });
  