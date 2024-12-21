// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LearnToEarn is ERC721, Ownable {
    uint256 public badgeCounter;
    uint256 public badgeCost;
    IERC20 public rewardToken;
    mapping(address => uint256[]) public userBadges;
    
    // Event to notify when a badge is minted
    event BadgeMinted(address indexed user, uint256 badgeId, uint256 rewardAmount);

    // Constructor initializes the contract with the token and badge cost
    constructor(
        string memory name,
        string memory symbol,
        IERC20 _rewardToken,
        uint256 _badgeCost
    ) 
        ERC721(name, symbol)
        Ownable(msg.sender)  // Initialize Ownable with the deployer as the initial owner
    {
        badgeCounter = 0;            // Start with 0 badges minted
        badgeCost = _badgeCost;      // Set the initial cost for earning badges (in ERC-20 tokens)
        rewardToken = _rewardToken;   // Set the ERC-20 token used for rewards
    }

    // Mint a badge for a user when they complete a milestone
    function mintBadge(address to) external onlyOwner {
        require(to != address(0), "Invalid address"); // Ensure the recipient address is valid
        uint256 badgeId = badgeCounter;
        
        _safeMint(to, badgeId); // Mint the badge NFT for the user
        badgeCounter++; // Increment the badge counter
        
        // Reward the user with the platform's native ERC-20 token
        rewardToken.transfer(to, badgeCost);
        
        // Store the badge in the user's list of badges
        userBadges[to].push(badgeId);
        
        // Emit the BadgeMinted event
        emit BadgeMinted(to, badgeId, badgeCost);
    }

    // Get a list of badges owned by a specific user
    function getUserBadges(address user) external view returns (uint256[] memory) {
        return userBadges[user];
    }

    // Set the badge cost (can be used to change the reward amount in ERC-20 tokens)
    function setBadgeCost(uint256 newCost) external onlyOwner {
        badgeCost = newCost;
    }

    // Withdraw contract's ETH balance (only the owner can withdraw)
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Withdraw the ERC-20 tokens from the contract (only the owner can withdraw)
    function withdrawERC20() external onlyOwner {
        uint256 balance = rewardToken.balanceOf(address(this));
        require(balance > 0, "No ERC20 tokens to withdraw");
        rewardToken.transfer(owner(), balance);
    }

    // Accept incoming ETH (the contract can receive ETH)
    receive() external payable {}
}