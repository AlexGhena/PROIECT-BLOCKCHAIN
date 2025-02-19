// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ReputationLibrary {
    function getWeight(uint256 feedbackTimestamp, uint256 currentTimestamp) internal pure returns (uint256) {
        uint256 age = currentTimestamp - feedbackTimestamp;
        if(age < 30 days) {
            return 1000;
        } else if(age < 60 days) {
            return 800;
        } else {
            return 500;
        }
    }
}

interface IReputationSystem {
    function addFeedback(address freelancer, uint256 points) external payable;
    function getReputation(address freelancer) external view returns (uint256);
}

contract ReputationSystem is IReputationSystem {
    using ReputationLibrary for uint256;
    
    address public owner;
    uint256 public constant FEEDBACK_FEE = 0.01 ether;
    
    struct Feedback {
        address client;
        uint256 points;
        uint256 timestamp;
    }
    
    mapping(address => Feedback[]) public feedbacks;
    ReputationToken public reputationToken;
    
    event FeedbackAdded(address indexed freelancer, address indexed client, uint256 points, uint256 timestamp);
    event Withdraw(address indexed owner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function setTokenAddress(address tokenAddress) external onlyOwner {
        reputationToken = ReputationToken(tokenAddress);
    }
    
    function addFeedback(address freelancer, uint256 points) external payable override {
        require(msg.value >= FEEDBACK_FEE, "Taxa insuficienta");
        require(points > 0, "Punctele trebuie sa fie > 0");
        
        Feedback memory fb = Feedback({
            client: msg.sender,
            points: points,
            timestamp: block.timestamp
        });
        
        feedbacks[freelancer].push(fb);
        emit FeedbackAdded(freelancer, msg.sender, points, block.timestamp);
        
        if(address(reputationToken) != address(0)) {
            reputationToken.mint(freelancer, points * 1e18);
        }
    }
    
    function getReputation(address freelancer) external view override returns (uint256) {
        Feedback[] memory fbs = feedbacks[freelancer];
        uint256 totalReputation = 0;
        for(uint256 i = 0; i < fbs.length; i++){
            uint256 weight = ReputationLibrary.getWeight(fbs[i].timestamp, block.timestamp);
            totalReputation += (fbs[i].points * weight) / 1000;
        }
        return totalReputation;
    }
    
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }
    
    function sendEther(address payable recipient, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Fonduri insuficiente in contract");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer ETH esuat");
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nu exista fonduri de retras");
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Retragerea esuata");
        emit Withdraw(owner, balance);
    }
    
    receive() external payable {}
    fallback() external payable {}
}

contract ReputationToken {
    string public name = "Reputation Token";
    string public symbol = "REP";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    address public minter;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    modifier onlyMinter() {
        require(msg.sender == minter, "Nu esti minter");
        _;
    }
    
    constructor() {
        minter = msg.sender;
    }
    
    function setMinter(address newMinter) external onlyMinter {
        require(newMinter != address(0), "Adresa invalida");
        minter = newMinter;
    }
    
    function mint(address to, uint256 amount) external onlyMinter {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Balanta insuficienta");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Balanta insuficienta");
        require(allowance[from][msg.sender] >= amount, "Allowance depasit");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}

contract ReputationClient {
    IReputationSystem public reputationSystem;
    
    constructor(address _reputationSystemAddress) {
        reputationSystem = IReputationSystem(_reputationSystemAddress);
    }
    
    function getMyReputation() external view returns (uint256) {
        return reputationSystem.getReputation(msg.sender);
    }
    
    function provideFeedback(address freelancer, uint256 points) external payable {
        reputationSystem.addFeedback{value: msg.value}(freelancer, points);
    }
}
