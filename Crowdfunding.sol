// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding{
    string public name;
    string public description;
    uint256 public goal;
    uint256 public deadline;
    address public owner;
    bool public paused;

    enum CampaignState { Active, Sucessful, Failed}
    CampaignState public state;

    
    struct Tier {
        string name;
        uint256 amount;
        uint256 backers;
    }
    struct Backer {
        uint256 totalContribution;
        mapping(uint256 => bool) fundedTiers;
        
    }

    Tier[] public tiers;
    mapping (address => Backer) public backers;

    modifier OnlyOwner() {
        require (msg.sender == owner,"Not the Owner");
        _;
    }

    modifier  notPaused(){
        require(!paused,"The Campaign is paused!");
        _;
    }

    modifier campainOpen(){
        require(state == CampaignState.Active, "Campain is Not Active");
        _;
    }

    constructor(string memory _name,string memory _description, uint256 _goal, uint256 _durationInDays){
        name = _name;
        description = _description;
        goal = _goal;
        deadline = block.timestamp + (_durationInDays*1 days);
        owner = msg.sender;
        state = CampaignState.Active;
    }
    function checkAndUpdateCampaignState() internal  {
        if(state == CampaignState.Active){
            if (block.timestamp>= deadline){
                state = address(this).balance >=goal ? CampaignState.Sucessful : CampaignState.Failed;
            } else {
                state = address(this).balance >=goal ? CampaignState.Sucessful : CampaignState.Active;
            }
        }
        
    }
    function fund(uint256 _tierIndex) public payable campainOpen notPaused{
        require(_tierIndex < tiers.length,"Invalid tier");
        require(msg.value == tiers[_tierIndex].amount, "Incorrect Amount");

        tiers[_tierIndex].backers++;
        backers[msg.sender].totalContribution+=msg.value;
        backers[msg.sender].fundedTiers[_tierIndex];
        checkAndUpdateCampaignState();



    }

    function addTier(
        string memory _name,
        uint256 _amount

    ) public OnlyOwner{
        require(_amount>0,"Amount should be higher than zero");
        tiers.push(Tier(_name, _amount,0));


    }

    function removeTier(uint256 _index) public {
        require(_index<tiers.length, "Tier doesn't exist");
        tiers[_index] = tiers[tiers.length-1];
        tiers.pop();
    }





    function withdraw() public OnlyOwner{
        // require(msg.sender==owner, "Only owner can withdraw");
        //  require(address(this).balance >=goal, "Goal not reached");
        checkAndUpdateCampaignState();
        require(state == CampaignState.Sucessful, "Campain not sucessful");


        uint256 balance = address(this).balance;
        require(balance>0,"No balance to withdraw");
        
        payable(owner).transfer(balance);
    }
    function getBalance() public view returns (uint256){
        return address(this).balance;

    }
    function refund() public {
        checkAndUpdateCampaignState();
        // require(state == CampaignState.Failed, "Refund Impossible");
        uint256 amount = backers[msg.sender].totalContribution;
        require(amount>0, "You already Caimed your contribution");
        backers[msg.sender].totalContribution = 0;
        payable(msg.sender).transfer(amount);
    }
    function hasFundedTier(address _backer, uint256 _tierIndex) public view returns (bool){
        return backers[_backer].fundedTiers[_tierIndex];
    }
    function getTiers() public view returns (Tier[] memory){
        return tiers;
    }

    function togglePause() public OnlyOwner{
        paused = !paused;

    }
    function getCampaignStatus() public view returns (CampaignState){
        if (state == CampaignState.Active && block.timestamp>deadline){
            return address(this).balance >= goal ? CampaignState.Sucessful : CampaignState.Failed;
        }
        return state;
    }

    function extendDeadline(uint256 _daysToAdd) public OnlyOwner campainOpen {
        deadline+= _daysToAdd + 1 days;
    }
}