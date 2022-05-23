//SPDX-License-Identifier: GPL-3.0

pragma solidity >0.6.0 <0.9.0;

contract CrowdFunding{
    mapping(address=>uint) public contributors_contribution; //contributors[msg.sender]= 1 ether
    address public manager; 
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;
    
    struct Request{
        string description0fRequest;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }
    mapping(uint=>Request) public requests;

    uint public numRequests;

    constructor(uint _target,uint _deadline){
        target = _target;
        deadline = block.timestamp + _deadline; 
        minimumContribution = 1 ether;
        manager = msg.sender;
    }
    
    function sendEth() public payable{
        require(block.timestamp < deadline,"Deadline has passed for the contribution");
        require(msg.value >= minimumContribution,"Minimum Contribution is not met");
        
        if(contributors_contribution[msg.sender]== 0){
            noOfContributors++; 
        }
        contributors_contribution[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public{
        require(raisedAmount<target && contributors_contribution[msg.sender]>0,"You are not eligible for the refund");
        address payable user = payable(msg.sender);
        user.transfer(contributors_contribution[msg.sender]);
        contributors_contribution[msg.sender] = 0;
    }

    modifier onlyManger(){
        require(msg.sender==manager,"Only manager can call this function");
        _;
    }

    function createRequests(string memory _description0fRequest,address payable _recipientAddress,uint _requestValue) public onlyManger{
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description0fRequest=_description0fRequest;
        newRequest.recipient=_recipientAddress;
        newRequest.value=_requestValue; 
        newRequest.completed=false;
        newRequest.noOfVoters=0;
    }

    function voting(uint _requestNo) public{
        require(contributors_contribution[msg.sender]>0,"You must be a contributor please do contribution to vote");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyManger{
        require(noOfContributors > 7, "Sufficient Number of contributors have not yet contributed");
        require(raisedAmount>=target);
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed==false,"The request has been completed");
        require(thisRequest.noOfVoters > noOfContributors/2,"Majority does not support");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }
}
