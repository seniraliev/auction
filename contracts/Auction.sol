
pragma solidity >=0.6.0 <0.8.0;
import './SafeMath.sol';



contract Project {
    using SafeMath for uint256;
    
    // Data structures
    enum State {
        Fundraising,
        Expired,
        Successful
    }

    // State variables
    address payable public _auctionOwner;  //person who deploys the contract A.K.A Auction Owner
    uint256 public lastHigh; // new bids should be higher than this
    uint256 public completeAt; //timestamp when the bid ends
    address public winner; //the person who wins the bid
    string public title;
    string public description;
    uint256 public auctionDeadline; //timestamp when the auction expires
    State public state = State.Fundraising; // initialize on create
    mapping (address => uint) public bids; //just to keep track of contributions
    bool stillRaising;
    bool expired;

    // Event that will be emitted whenever funding will be received
    event bidReceived(address contributor, uint amount);
    // Event that will be emitted whenever the project starter has received the funds
    event auctionerPaid(uint256 _totalPaid);

    // Modifier to check current state
    modifier inState(State _state) {
        require(state == _state);
        _;
    }


    modifier isCreator() {
        require(msg.sender == _auctionOwner,"yikes, you didn't create this auction");
        _;
    }
    
    modifier isHigher(uint256 amountSent){
        require (bids[msg.sender]+amountSent>lastHigh,"your bid should be higher than the current bid");
        _;
    }
    
    modifier stillAcceptingBids{
       require(stillRaising=true);
       
        require (block.timestamp<=auctionDeadline);
        _;
    }
    
    modifier auctionFinished{
        
     require (stillRaising==false);
   _;
    }

    constructor
    (
        string memory auctionTitle,
        string memory auctionDesc,
        uint256 _auctionDeadline,
        uint256 minStartingAmount
    ) public {
        _auctionOwner = msg.sender;
        title = auctionTitle;
        description = auctionDesc; 
        lastHigh = minStartingAmount; //maybe 0.1bnb
          stillRaising=true;
        auctionDeadline=_auctionDeadline; //in unix timestamp
    
    }


    function contribute() external stillAcceptingBids isHigher(msg.value) payable returns(bool){
        require(msg.sender != _auctionOwner);
        bids[msg.sender] = bids[msg.sender].add(msg.value);
        lastHigh=bids[msg.sender];
        emit bidReceived(msg.sender, msg.value);
        return true;
    }
    
    function checkHighestBid() public view returns(uint256){
        return lastHigh;
    }

    function acceptHighestBid() public isCreator{
        if ((block.timestamp<=auctionDeadline)) {
            expired=true;
            payOut();
        completeAt = block.timestamp;
    }
    else{
         expired=true;
        payOut();
    }}

    /** @dev Function to give the received funds to project starter.
      */
    function payOut() internal returns (bool) {
        uint256 highestRaised = lastHigh;
        _auctionOwner.transfer(highestRaised);
        stillRaising=false;
        expired=true;
            emit auctionerPaid(lastHigh);
            return true;

    }

    function getRefund() public auctionFinished returns (bool) {
        require(bids[msg.sender] > 0);

        uint256 amountToRefund = bids[msg.sender];
        bids[msg.sender] = 0;
        msg.sender.send(amountToRefund);
        return true;
    }

  
} 