/*
  (c) QzIP Blockchain Technlogy LLP (qzip.business)
  Apache 2.0 License

*/

pragma solidity ^0.4.24;

/** 
 * @title  Fair Play Lottery Contract with Floor Limit for the Jackpot
 * @author Ashish Banerjee (ashish@qzip.in)
 * @notice Fair Play Lottery (No Warraties) with Floor Limit for the Jackpot
 * @dev  Technology Demonstrator for Pseudo Random number.
 * version v02 - 06-aug-2018
 *
 * NOTE: Many countries forbit online lotteries. Check the law of the land before deploying
 *       This is a Technology Demonstrator for  Pseudo Random number generator.
 *        ABSOLUTELY NO WARRANTIES, USE AT YOUR OWN RISK.
*/

contract FloorLottery {
    uint constant public version = 0x02;
    address public creator ;
    address[] public participants;
   // mapping(bytes32 => uint) public partyRegister; // zero == not present. 1 == Records[0]
    
    modifier onlyCreator() { // Modifier
        require(
            msg.sender == creator,
            "Only creator can call this."
        );
        _;  // function content being modified is placed here
    }
    uint public adminFee;
    uint public ticketPrice;
    uint public jackpot;
    uint public minPot;
    event EvtJackPotWinner(
        address winner,
        uint    prize
    );
    
    modifier fees() {
       require (
           msg.value >= ticketPrice,
           "Service fees inadequately funded"
        );    
        
        _;
    }
    constructor( uint fee, uint ticket, uint floor ) public {
        require(fee < ticket, "Can't charge more than the ticket price, Duh!");
        creator = msg.sender;
        adminFee = fee;
        minPot = floor;
        ticketPrice = ticket;
    }
   function endRaffle() public onlyCreator {

       // declare the winner and send jackpot
       if(participants.length > 0 ) {
           if(jackpot >= minPot) {
          address  winr = getWinner();
          winr.transfer(jackpot);
          emit EvtJackPotWinner(winr, jackpot);               
           } else {
               refundMoney();
           }

       }
       // commit sucide
       selfdestruct(creator);
   }
   function buyticket() public  payable fees {
       jackpot += (ticketPrice - adminFee);
       participants.push(msg.sender);
   }
   function getWinner() internal view returns (address) {
       bytes32 pseuorand = keccak256(abi.encodePacked(creator,now)) ;
       for(uint i=0; i < participants.length; i++ ) {
           pseuorand = keccak256(abi.encodePacked(pseuorand, participants[i] ));
       }
       
       return participants[ uint256(pseuorand) % participants.length];
       
   }
   function refundMoney() internal {
       for(uint i=0; i < participants.length; i++ ) {
            participants[i].transfer(ticketPrice);
           
       }
   }

}

