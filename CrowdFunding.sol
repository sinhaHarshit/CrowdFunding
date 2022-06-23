//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 < 0.9.0;

contract CrowdFunding{
    mapping(address=>uint) public contributors; //contributors[msg.sender]=100
    address public manager; 
    uint public minContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public numContributors;
    
    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }

    mapping(uint=>Request) public requests;
    uint public numRequests;

    constructor(uint _target,uint _deadline){
        target=_target;
        deadline=block.timestamp+_deadline; 
        minContribution=100 wei;
        manager=msg.sender;
    }

    modifier beforeDeadline {
        require(block.timestamp < deadline, "Deadline has passed");
        _;
    }

    modifier afterDealine {
        require(block.timestamp > deadline, "Deadline has not passed yet, not eligible for refund.");
        _;
    }

    modifier targetNotMet {
        require(raisedAmount < target, "Raised amount meets the target, not eligible for refund.");
        _;
    }

    modifier validContributuion {
        require(msg.value >=minContribution,"Minimum Contribution is not met");
        _;
    }

    modifier targetMet {
        require(raisedAmount>=target);
        _;
    }

    modifier validContributor {
        require(contributors[msg.sender]>0, "You are not a contributor");
        _;
    }

    modifier majoritySupports(uint _requestNo) {
        require(requests[_requestNo].noOfVoters > numContributors/2, "Majority does not support the request");
        _;
    }

    modifier onlyManger(){
        require(msg.sender==manager,"Only manager can calll this function");
        _;
    }
    
    function sendEth() public payable beforeDeadline validContributuion{

        if(contributors[msg.sender]==0){
            numContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }


    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }


    function refund() public afterDealine targetNotMet validContributor{
        address payable user=payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
    }


    function createRequests(string memory _description,address payable _recipient,uint _value) public onlyManger{
        //Request storage newRequest = requests[numRequests];
        
        requests[numRequests].description=_description;
        requests[numRequests].recipient=_recipient;
        requests[numRequests].value=_value;
        requests[numRequests].completed=false;
        requests[numRequests].noOfVoters=0;

        numRequests++;
    }


    function voteRequest(uint _requestNo) public validContributor{ 
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }


    function makePayment(uint _requestNo) public onlyManger targetMet majoritySupports(_requestNo){
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed==false,"The request has been completed");
        //require(thisRequest.noOfVoters > numContributors/2,"Majority does not support");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }
}
