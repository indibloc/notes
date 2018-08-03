/*
  (c) QzIP Blockchain Technlogy LLP (qzip.business)
  Apache 2.0 License

*/

pragma solidity ^0.4.24;

/** 
 * @title  Fair Play Lottery Contract
 * @author Ashish Banerjee (ashish@qzip.in)
 * @notice Fair Play Lottery (No Warraties) 
 * @dev  Technology Demonstrator for Pseudo Random number.
 * version v01 - 03-aug-2018
 *
 * NOTE: Many countries forbit online lotteries. Check the law of the land before deploying
 *       This is a Technology Demonstrator for  Pseudo Random number generator.
 *        ABSOLUTELY NO WARRANTIES, USE AT YOUR OWN RISK.
*/

contract Lottery {
    address public creator ;
    address[] public participants;
    mapping(bytes32 => uint) public partyRegister; // zero == not present. 1 == Records[0]
    
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
    constructor( uint fee, uint ticket ) public {
        require(fee < ticket, "Can't charge more than the ticket price, Duh!");
        creator = msg.sender;
        adminFee = fee;
        ticketPrice = ticket;
    }
   function endRaffle() public onlyCreator {
       // declare the winner and send jackpot
       if(participants.length > 0) {
          address  winr = getWinner();
          winr.transfer(jackpot);
          emit EvtJackPotWinner(winr, jackpot);
       }
       // commit sucide
       selfdestruct(creator);
   }
   function buyticket() public  payable fees {
       address(this).transfer(ticketPrice);
       jackpot += (ticketPrice - adminFee);
   }
   function getWinner() internal returns (address) {
       bytes32 pseuorand = keccak256(creator) ;
       for(uint i=0; i < participants.length; i++ ) {
           pseuorand = keccak256(pseuorand, participants );
       }
       
       return participants[ uint256(pseuorand) % participants.length];
       
   }
}

