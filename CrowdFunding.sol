// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// This contract allows multiple contributors to pool funds, set funding goals, and 
// withdraw or refund funds based on the campaign's success
//Also generate the most generous contributor from the campaigns

contract CrowdFunding {

    //State variables go here
    
    // Struct to represent a campaign
    struct Campaign {
        address owner;
        uint goal;
        uint deadline;
        uint totalFunds;
        address mostGenerousContributor;
        uint highestContribution;
        mapping(address => uint) contributions;
        bool exists;
    }

    // Mapping to store campaigns by ID
    mapping(uint => Campaign) public campaigns;
    uint public campaignCount;

    // Events
    event CampaignCreated(uint campaignId, address indexed owner, uint goal, uint deadline);
    event FundReceived(uint campaignId, address indexed contributor, uint amount);
    event GoalReached(uint campaignId, uint totalFunds);
    event FundsWithdrawn(uint campaignId, address indexed owner, uint amount);
    event RefundIssued(uint campaignId, address indexed contributor, uint amount);

    // Modifier to restrict access to campaign owner
    modifier onlyOwner(uint campaignId) {
        require(campaigns[campaignId].exists, "Campaign does not exist");
        require(msg.sender == campaigns[campaignId].owner, "Only the owner can perform this function");
        _;
    }

    // Modifier to check if a campaign exists
    modifier campaignExists(uint campaignId) {
        require(campaigns[campaignId].exists, "Campaign does not exist");
        _;
    }

    // Function to create a new campaign
    function createCampaign(uint _goal, uint _duration) public {
        require(_goal > 0, "Goal must be greater than zero");
        require(_duration > 0, "Duration must be greater than zero");

        campaignCount++;
        Campaign storage newCampaign = campaigns[campaignCount];
        newCampaign.owner = msg.sender;
        newCampaign.goal = _goal;
        newCampaign.deadline = block.timestamp + _duration;
        newCampaign.exists = true;

        emit CampaignCreated(campaignCount, msg.sender, _goal, newCampaign.deadline);
    }

    // Function to contribute funds to a specific campaign
    function contribute(uint campaignId) public payable campaignExists(campaignId) {
        Campaign storage campaign = campaigns[campaignId];

        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(msg.value > 0, "Contribution must be greater than zero");

        campaign.contributions[msg.sender] += msg.value;
        campaign.totalFunds += msg.value;

        // Update most generous contributor
        if (campaign.contributions[msg.sender] > campaign.highestContribution) {
            campaign.highestContribution = campaign.contributions[msg.sender];
            campaign.mostGenerousContributor = msg.sender;
        }

        emit FundReceived(campaignId, msg.sender, msg.value);

        if (campaign.totalFunds >= campaign.goal) {
            emit GoalReached(campaignId, campaign.totalFunds);
        }
    }

    // Function to withdraw funds if the goal is met
    function withdrawFunds(uint campaignId) public onlyOwner(campaignId) {
        Campaign storage campaign = campaigns[campaignId];

        require(campaign.totalFunds >= campaign.goal, "Goal not reached");
        require(block.timestamp >= campaign.deadline, "Campaign is still ongoing");

        uint amount = address(this).balance;
        payable(campaign.owner).transfer(amount);

        emit FundsWithdrawn(campaignId, campaign.owner, amount);
    }

    // Function to issue refunds if the goal is not met
    function refund(uint campaignId) public campaignExists(campaignId) {
        Campaign storage campaign = campaigns[campaignId];

        require(block.timestamp >= campaign.deadline, "Campaign is still ongoing");
        require(campaign.totalFunds < campaign.goal, "Goal was reached");

        uint contributedAmount = campaign.contributions[msg.sender];
        require(contributedAmount > 0, "No contributions to refund");

        campaign.contributions[msg.sender] = 0;

        payable(msg.sender).transfer(contributedAmount);

        emit RefundIssued(campaignId, msg.sender, contributedAmount);
    }

    // Function to get the most generous contributor of a campaign
    function getMostGenerousContributor(uint campaignId) public view campaignExists(campaignId) returns (address, uint) {
        Campaign storage campaign = campaigns[campaignId];
        return (campaign.mostGenerousContributor, campaign.highestContribution);
    }
}