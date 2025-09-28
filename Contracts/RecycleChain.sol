// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title RecycleChain
 * @dev A smart contract for incentivizing recycling through blockchain rewards
 * @author RecycleChain Team
 */
contract RecycleChain {
    
    // State variables
    address public owner;
    uint256 public totalRecycledItems;
    uint256 public rewardRate = 10; // tokens per recycled item
    
    // Structs
    struct User {
        uint256 recycledCount;
        uint256 tokenBalance;
        bool isRegistered;
        uint256 lastRecycleTime;
    }
    
    struct RecycleRecord {
        address user;
        string itemType;
        uint256 quantity;
        uint256 timestamp;
        bool verified;
    }
    
    // Mappings
    mapping(address => User) public users;
    mapping(uint256 => RecycleRecord) public recycleRecords;
    mapping(string => bool) public acceptedMaterials;
    
    // Events
    event UserRegistered(address indexed user, uint256 timestamp);
    event ItemRecycled(address indexed user, string itemType, uint256 quantity, uint256 tokensEarned);
    event RecordVerified(uint256 indexed recordId, address verifier);
    event TokensRedeemed(address indexed user, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyRegistered() {
        require(users[msg.sender].isRegistered, "User must be registered");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        
        // Initialize accepted materials
        acceptedMaterials["plastic"] = true;
        acceptedMaterials["glass"] = true;
        acceptedMaterials["paper"] = true;
        acceptedMaterials["metal"] = true;
        acceptedMaterials["electronic"] = true;
    }
    
    /**
     * @dev Core Function 1: Register a new user in the recycling system
     */
    function registerUser() external {
        require(!users[msg.sender].isRegistered, "User already registered");
        
        users[msg.sender] = User({
            recycledCount: 0,
            tokenBalance: 0,
            isRegistered: true,
            lastRecycleTime: 0
        });
        
        emit UserRegistered(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Core Function 2: Record recycled items and earn tokens
     * @param itemType Type of material recycled (plastic, glass, paper, etc.)
     * @param quantity Number of items recycled
     */
    function recycleItem(string memory itemType, uint256 quantity) external onlyRegistered {
        require(quantity > 0, "Quantity must be greater than zero");
        require(acceptedMaterials[itemType], "Material type not accepted");
        
        // Create record
        uint256 recordId = totalRecycledItems;
        recycleRecords[recordId] = RecycleRecord({
            user: msg.sender,
            itemType: itemType,
            quantity: quantity,
            timestamp: block.timestamp,
            verified: false
        });
        
        // Update user stats
        users[msg.sender].recycledCount += quantity;
        users[msg.sender].lastRecycleTime = block.timestamp;
        
        // Calculate and award tokens
        uint256 tokensEarned = quantity * rewardRate;
        users[msg.sender].tokenBalance += tokensEarned;
        
        totalRecycledItems++;
        
        emit ItemRecycled(msg.sender, itemType, quantity, tokensEarned);
    }
    
    /**
     * @dev Core Function 3: Redeem tokens for rewards
     * @param amount Number of tokens to redeem
     */
    function redeemTokens(uint256 amount) external onlyRegistered {
        require(amount > 0, "Amount must be greater than zero");
        require(users[msg.sender].tokenBalance >= amount, "Insufficient token balance");
        
        users[msg.sender].tokenBalance -= amount;
        
        // In a real implementation, this would trigger external reward distribution
        // For now, we just emit an event
        emit TokensRedeemed(msg.sender, amount);
    }
    
    // Additional utility functions
    
    /**
     * @dev Verify a recycle record (only owner can verify)
     * @param recordId ID of the record to verify
     */
    function verifyRecord(uint256 recordId) external onlyOwner {
        require(recordId < totalRecycledItems, "Invalid record ID");
        require(!recycleRecords[recordId].verified, "Record already verified");
        
        recycleRecords[recordId].verified = true;
        emit RecordVerified(recordId, msg.sender);
    }
    
    /**
     * @dev Add new accepted material type
     * @param materialType New material type to accept
     */
    function addAcceptedMaterial(string memory materialType) external onlyOwner {
        acceptedMaterials[materialType] = true;
    }
    
    /**
     * @dev Update reward rate
     * @param newRate New reward rate per recycled item
     */
    function updateRewardRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "Reward rate must be positive");
        rewardRate = newRate;
    }
    
    /**
     * @dev Get user information
     * @param userAddress Address of the user
     */
    function getUserInfo(address userAddress) external view returns (
        uint256 recycledCount,
        uint256 tokenBalance,
        bool isRegistered,
        uint256 lastRecycleTime
    ) {
        User memory user = users[userAddress];
        return (user.recycledCount, user.tokenBalance, user.isRegistered, user.lastRecycleTime);
    }
    
    /**
     * @dev Get recycling statistics
     */
    function getStats() external view returns (uint256 totalItems, uint256 currentRewardRate) {
        return (totalRecycledItems, rewardRate);
    }
}
