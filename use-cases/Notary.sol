/*
  (c) QzIP Blockchain Technlogy LLP (qzip.business)
  Apache 2.0 License

*/

pragma solidity ^0.4.24;
//pragma experimental ABIEncoderV2;

/** 
 * @title QzIP Notary Contract
 * @author Ashish Banerjee (ashish@qzip.in)
 * @notice Notary Service (annonymized)
 * @dev  Blind Notarize with KYC.
 * version v01 - 24-July-2018
 *
 * 
*/
contract Notarize {
    address public creator ;
    bytes32 public titleHash;
    mapping(address => bool) kycWhitelisted;
    uint public adminFee;
    bytes32  public notaryServiceRegistry; 
    uint constant public version = 1;
    struct Record {
        uint tmstamp;
        bytes32 docHash;
        address submitter;
        uint    prevRecsLen;  // previous record with same docHash
    }
    mapping(bytes32 => uint) public hashRegister; // zero == not present. 1 == Records[0]
    Record[] public records;
    
    event EvtNotaryService (
        bytes32 serviceHash,
        address  notary,
        bytes32  titleHash,
        uint     fee
    );
 
    event EvtNotarized (
        bytes32  serviceHash,
        address  notary,
        bytes32  titleHash,
        bytes32  docHash,
        address  petitioner,
        uint     recNdx
    );
    event EvtKycWhitelist (
        bytes32  serviceHash,
        address  notary,
        bytes32  titleHash,
        address  petitioner,
        bool     added
    );    
    
    event EvtClosedNotaryService (
        bytes32 serviceHash,
        address  notary,
        bytes32  titleHash
    );

    
    modifier onlyCreator() { // Modifier
        require(
            msg.sender == creator,
            "Only creator can call this."
        );
        _;  // function content being modified is placed here
    }
    
    modifier fees() {
       require (
           msg.value >= adminFee,
           "Service fees inadequately funded"
        );    
        
        _;
    }
    constructor( bytes32 title_Hash, uint fee ) public {
        creator = msg.sender;
        titleHash = title_Hash;
        adminFee = fee;
        notaryServiceRegistry = keccak256("QzIP Notary Service");
        emit EvtNotaryService(notaryServiceRegistry, msg.sender,titleHash, fee);
    }
    
    
    function reviseFees( uint fee) public onlyCreator {
        adminFee = fee;
        emit EvtNotaryService(notaryServiceRegistry, msg.sender,titleHash, fee);
   }    
    function kycWhitelist(address who) public onlyCreator {
        kycWhitelisted[who] = true;
        emit EvtKycWhitelist (notaryServiceRegistry, creator, titleHash, who, true);
   }
    function unWhitelist(address who) public onlyCreator {
        kycWhitelisted[who] = false;
        emit EvtKycWhitelist (notaryServiceRegistry, creator, titleHash, who, false);
   }   
    function decuctFee( uint256 amount) internal {
       require(creator.send(amount), "Unpaid Fee");

   }   
   function notarize(bytes32 doc_Hash) public payable fees returns ( uint ){
        decuctFee(adminFee);   
        
        require(
            kycWhitelisted[msg.sender],
            "Please do KYC procedure first."
        );     
        uint ndx = hashRegister[doc_Hash];
        Record memory rec;
        
        rec.tmstamp = now;
        rec.docHash = doc_Hash;
        rec.submitter =  msg.sender;
        rec.prevRecsLen = ndx ; 
        
        uint recLenght = records.push(rec);
        
        emit EvtNotarized (notaryServiceRegistry, creator, titleHash, doc_Hash, msg.sender, recLenght-1);
      
        return recLenght;
   }
   function recordLen() public view  returns (uint) {
      return records.length;
    }
    function closeNotaryService() public onlyCreator {
        emit EvtClosedNotaryService (notaryServiceRegistry,creator, titleHash);
    
        selfdestruct(creator);
    }
}

