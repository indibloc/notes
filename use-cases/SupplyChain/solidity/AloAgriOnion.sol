/*
  (c) QzIP Blockchain Technlogy LLP (qzip.business)
  Apache 2.0 License

*/

pragma solidity ^0.4.24;
//pragma experimental ABIEncoderV2;

/** 
 * @title Alo Agri Onion Contract
 * @author Ashish Banerjee (ashish@qzip.in)
 * @notice Ricardian Smart Contract (annonymized)
 * @dev  Assummes that buyer and sellers are not part of blockchain network.
 * version v02 - 01-July-2018
 * 
 * This version assumes that the buyer and seller both do not have Key pair.
 * for these entities annonymous id are used.
 
 * Sample: https://docs.google.com/document/d/1v9GJkyrCBV7Mzs9vngeosGyhMHb3KSYc6Wgcx5o7zSI/edit
 * 
 *** Events **
 * https://docs.google.com/presentation/d/1HLbSbem6IJwdyzAB6CbojpIa9-c_uL__9X0qz1rMgaE/edit#slide=id.g3c331a5437_0_0
 * 
 * [Start Escrow] --> create contract
 * [Buyer Accepted] 
 * [Seller Accepted]
 * [Arbitrator Approved]
 * [Escrow created]
 * [shipped]
 * [delivered]
 * [Buyer Acknowledged] or [DisputeTimeout]
 * [Escrow Released]
 * 
 * [Buyer Disputed]
 * [Aritration Started]
 * [Aritration Resolved]
 * [Arbitration Deadlocked]
 * [Court Refred]
 * [Court Ordered]
 */
 
contract AloAgriOnion {
    
    enum States {
        Init, BuyerAccepted, SellerAccepted, AriratorApproved, EscrowCreated,
        Shipped, Delivered, BuyerAcknowledged, DisputeTimeout, EscrowReleased,
        BuyerDisputed, AritrationStarted, AritrationResolved, AritrationDeadlocked,
        CourtReferred, CourtOrdered  , Record, END
    }
    
    struct Status {
        States state;
        uint tmstamp;
        string docId;
        string docmimeType;
        bytes32 docHash;
        address createdBy;
        
    }
    mapping(uint => bool) nextStates; // 
    address public creator ;
    address public arbitrator ;
    address public auditor ;
    string  public buyerId ;
    string  public sellerId ;
    string  public contractId ;
    
    Status[] public status;  
    
    event EvtContractStatusChanged (
        string  contractId,
        string  statusType,   // enum are not visible outside solidity
        Status  status
    
    );
    
    constructor(string contract_id, string  buyer,  string  seller,
                string contractMimeType, bytes32 contract_Hash 
               ) public {
        creator = msg.sender;
        buyerId = buyer;
        sellerId = seller;
        
        Status memory st;
        st.state = States.Init;
        st.tmstamp = now;
        st.docId = contract_id;
        st.docmimeType = contractMimeType;
        st.docHash = contract_Hash;
        st.createdBy =  msg.sender;
        
        status.push(st);
        
       emit EvtContractStatusChanged (contractId,"Init", st); 
       
       // set next allowed states
       resetNextStates();
       nextStates[uint(States.BuyerAccepted)] = true;
       nextStates[uint(States.SellerAccepted)] = true;   
       nextStates[uint(States.Record)] = true; 
    }
    
    modifier onlyCreator() { // Modifier
        require(
            msg.sender == creator,
            "Only creator can call this."
        );
        _;  // function content being modified is placed here
    }
    
   function addArbitrator(address who) public onlyCreator {
        arbitrator = who;
       
   }
   function addAuditor(address who) public onlyCreator {
        auditor = who;
       
   }   
   /**
    * @dev Record can be added within any stage.
    */
   function addRecord(string docId, string docmimeType, bytes32 docHash) public {
        require(
         msg.sender == arbitrator || msg.sender == creator || msg.sender == auditor,
         "Not in role"
        );     
        Status memory st;
        st.state = States.Record;
        st.tmstamp = now;
        st.docId = docId;
        st.docmimeType = docmimeType;
        st.docHash = docHash;
        st.createdBy =  msg.sender;
        
        status.push(st);
        
       emit EvtContractStatusChanged (contractId,"Record", st);
   }
   function buyerAccepted(string docId, string docmimeType, bytes32 docHash) 
        public onlyCreator {
        require( 
          nextStates[uint(States.BuyerAccepted)],
           "Invalid state, should be after Init or Seller Accepted"
        );
 
        Status memory st;
        st.state = States.BuyerAccepted;
        st.tmstamp = now;
        st.docId = docId;
        st.docmimeType = docmimeType;
        st.docHash = docHash;
        st.createdBy =  msg.sender;
        
        status.push(st);
        
       emit EvtContractStatusChanged (contractId,"BuyerAccepted", st);      
       
      // set next allowed states
       resetNextStates();
       nextStates[uint(States.SellerAccepted)] = true;   
       nextStates[uint(States.Record)] = true;   
       nextStates[uint(States.AriratorApproved)] = true; 
       
   }
   function sellerAccepted(string docId, string docmimeType, bytes32 docHash) 
        public onlyCreator {
        require( 
          nextStates[uint(States.SellerAccepted)],
           "Invalid state, should be after Init or Seller Accepted"
        );
 
        Status memory st;
        st.state = States.SellerAccepted;
        st.tmstamp = now;
        st.docId = docId;
        st.docmimeType = docmimeType;
        st.docHash = docHash;
        st.createdBy =  msg.sender;
        
        status.push(st);
        
       emit EvtContractStatusChanged (contractId,"SellerAccepted", st); 
         // set next allowed states
       resetNextStates();
       nextStates[uint(States.BuyerAccepted)] = true;   
       nextStates[uint(States.Record)] = true;   
       nextStates[uint(States.AriratorApproved)] = true; 
       
   }    
   
     modifier onlyArbitrator() { // Modifier
        require(
            msg.sender == arbitrator,
            "Only arbitrator can call this."
        );
        _;  // function content being modified is placed here
    }
    function approved(string docId, string docmimeType, bytes32 docHash) 
        public onlyArbitrator {
        uint ndx = status.length-1;
        uint8 accepted =0;
        for(; ndx > 0 ; ndx-- ) {
            if(status[ndx].state == States.BuyerAccepted ||
               status[ndx].state == States.SellerAccepted)
               accepted++;
            else if(!(status[ndx].state == States.Record)) 
                break;
             
        }     
        require( 
           accepted == 2 &&
           nextStates[uint(States.AriratorApproved)]
           ,
           "Invalid state, should be after Seller & Buyer both Accepted"
        );
 
        Status memory st;
        st.state = States.AriratorApproved;
        st.tmstamp = now;
        st.docId = docId;
        st.docmimeType = docmimeType;
        st.docHash = docHash;
        st.createdBy =  msg.sender;
        
        status.push(st);
        
       emit EvtContractStatusChanged (contractId,"AriratorApproved", st);  
       
       
       resetNextStates();
       nextStates[uint(States.EscrowCreated)] = true; 
       nextStates[uint(States.Record)] = true;   
       
   }    
   function escrowed(string docId, string docmimeType, bytes32 docHash)
            public onlyCreator {
        require( 
          nextStates[uint(States.EscrowCreated)],
           "Invalid state, should be after Aribtrator's approval"
        );
 
        Status memory st;
        st.state = States.EscrowCreated;
        st.tmstamp = now;
        st.docId = docId;
        st.docmimeType = docmimeType;
        st.docHash = docHash;
        st.createdBy =  msg.sender;
        
        status.push(st);
        
       emit EvtContractStatusChanged (contractId,"EscrowCreated", st); 
         // set next allowed states
       resetNextStates();
       nextStates[uint(States.Shipped)] = true;   
       nextStates[uint(States.Record)] = true;   
       nextStates[uint(States.BuyerDisputed)] = true; // shipping too late
       
   }   
   function shipped(string docId, string docmimeType, bytes32 docHash)
            public onlyCreator {
        require( 
          nextStates[uint(States.Shipped)],
           "Invalid state, should be after the Escrow is created"
        );
 
        Status memory st;
        st.state = States.Shipped;
        st.tmstamp = now;
        st.docId = docId;
        st.docmimeType = docmimeType;
        st.docHash = docHash;
        st.createdBy =  msg.sender;
        
        status.push(st);
        
       emit EvtContractStatusChanged (contractId,"Shipped", st); 
         // set next allowed states
       resetNextStates();
       nextStates[uint(States.Delivered)] = true;   
       nextStates[uint(States.Record)] = true;   
       nextStates[uint(States.BuyerDisputed)] = true; // shipping too late
       nextStates[uint(States.BuyerAcknowledged)] = true; 
       
   }   
    function delivered(string docId, string docmimeType, bytes32 docHash)
            public onlyCreator {
        require( 
          nextStates[uint(States.Delivered)],
           "Invalid state, should be after the shipping"
        );
 
        Status memory st;
        st.state = States.Delivered;
        st.tmstamp = now;
        st.docId = docId;
        st.docmimeType = docmimeType;
        st.docHash = docHash;
        st.createdBy =  msg.sender;
        
        status.push(st);
        
       emit EvtContractStatusChanged (contractId,"Delivered", st); 
         // set next allowed states
       resetNextStates();
       nextStates[uint(States.Record)] = true;   
       nextStates[uint(States.BuyerDisputed)] = true; // shipping too late
       nextStates[uint(States.BuyerAcknowledged)] = true; 
       nextStates[uint(States.DisputeTimeout)] = true;
   }   
    function buyerAcknowledged(string docId, string docmimeType, bytes32 docHash)
            public onlyCreator {
        require( 
          nextStates[uint(States.BuyerAcknowledged)],
           "Invalid state, should be after the shipping or delivery"
        );
 
        Status memory st;
        st.state = States.BuyerAcknowledged;
        st.tmstamp = now;
        st.docId = docId;
        st.docmimeType = docmimeType;
        st.docHash = docHash;
        st.createdBy =  msg.sender;
        
        status.push(st);
        
       emit EvtContractStatusChanged (contractId,"BuyerAcknowledged", st); 
         // set next allowed states
       resetNextStates();
       nextStates[uint(States.Record)] = true;   
       nextStates[uint(States.EscrowReleased)] = true; 

   } 
    function disputeTimeout(string docId, string docmimeType, bytes32 docHash)
            public onlyCreator {
        require( 
          nextStates[uint(States.DisputeTimeout)],
           "Invalid state, should be after the shipping or delivery"
        );
 
        Status memory st;
        st.state = States.DisputeTimeout;
        st.tmstamp = now;
        st.docId = docId;
        st.docmimeType = docmimeType;
        st.docHash = docHash;
        st.createdBy =  msg.sender;
        
        status.push(st);
        
       emit EvtContractStatusChanged (contractId,"DisputeTimeout", st); 
         // set next allowed states
       resetNextStates();
       nextStates[uint(States.Record)] = true;   
       nextStates[uint(States.EscrowReleased)] = true; 

   }    
    function escrowReleased(string docId, string docmimeType, bytes32 docHash)
            public onlyCreator {
        require( 
          nextStates[uint(States.EscrowReleased)],
           "Invalid state, should be after the shipping or delivery"
        );
 
        Status memory st;
        st.state = States.EscrowReleased;
        st.tmstamp = now;
        st.docId = docId;
        st.docmimeType = docmimeType;
        st.docHash = docHash;
        st.createdBy =  msg.sender;
        
        status.push(st);
        
       emit EvtContractStatusChanged (contractId,"EscrowReleased", st); 
         // set next allowed states
       resetNextStates();
       nextStates[uint(States.Record)] = true;   // audits or exceptions

   } 
   // exceptions:
   //       BuyerDisputed, AritrationStarted, AritrationResolved, AritrationDeadlocked,
   //       CourtReferred, CourtOrdered  
    function buyerDisputed(string docId, string docmimeType, bytes32 docHash)
            public onlyCreator {
        require( 
          nextStates[uint(States.BuyerDisputed)],
           "Invalid state, should be after the aprroval, shipping or delivery"
        );
 
        Status memory st;
        st.state = States.BuyerDisputed;
        st.tmstamp = now;
        st.docId = docId;
        st.docmimeType = docmimeType;
        st.docHash = docHash;
        st.createdBy =  msg.sender;
        
        status.push(st);
        
       emit EvtContractStatusChanged (contractId,"BuyerDisputed", st); 
         // set next allowed states
       resetNextStates();
       nextStates[uint(States.Record)] = true;   
       nextStates[uint(States.AritrationStarted)] = true; 

   }    
   function aritrationStarted(string docId, string docmimeType, bytes32 docHash)
            public onlyArbitrator {
        require( 
          nextStates[uint(States.AritrationStarted)],
           "Invalid state, should be after Buyer disputes"
        );
 
        Status memory st;
        st.state = States.AritrationStarted;
        st.tmstamp = now;
        st.docId = docId;
        st.docmimeType = docmimeType;
        st.docHash = docHash;
        st.createdBy =  msg.sender;
        
        status.push(st);
        
       emit EvtContractStatusChanged (contractId,"AritrationStarted", st); 
         // set next allowed states
       resetNextStates();
       nextStates[uint(States.Record)] = true;   
       nextStates[uint(States.AritrationResolved)] = true; 
       nextStates[uint(States.AritrationDeadlocked)] = true; 

   }       
   function aritrationResolved(string docId, string docmimeType, bytes32 docHash)
            public onlyArbitrator {
        require( 
          nextStates[uint(States.AritrationResolved)],
           "Invalid state, should be after Arbitration started"
        );
 
        Status memory st;
        st.state = States.AritrationResolved;
        st.tmstamp = now;
        st.docId = docId;
        st.docmimeType = docmimeType;
        st.docHash = docHash;
        st.createdBy =  msg.sender;
        
        status.push(st);
        
       emit EvtContractStatusChanged (contractId,"AritrationResolved", st); 
         // set next allowed states
       resetNextStates();
       nextStates[uint(States.Record)] = true;   
       nextStates[uint(States.EscrowReleased)] = true; 

   }  
   function aritrationDeadlocked(string docId, string docmimeType, bytes32 docHash)
            public onlyArbitrator {
        require( 
          nextStates[uint(States.AritrationDeadlocked)],
           "Invalid state, should be after Arbitration started"
        );
 
        Status memory st;
        st.state = States.AritrationDeadlocked;
        st.tmstamp = now;
        st.docId = docId;
        st.docmimeType = docmimeType;
        st.docHash = docHash;
        st.createdBy =  msg.sender;
        
        status.push(st);
        
       emit EvtContractStatusChanged (contractId,"AritrationDeadlocked", st); 
         // set next allowed states
       resetNextStates();
       nextStates[uint(States.Record)] = true;   
       nextStates[uint(States.CourtReferred)] = true; 

   }    
   function CourtReferred(string docId, string docmimeType, bytes32 docHash)
            public onlyCreator {
        require( 
          nextStates[uint(States.CourtReferred)],
           "Invalid state, should be after Arbitration deadlocked"
        );
 
        Status memory st;
        st.state = States.CourtReferred;
        st.tmstamp = now;
        st.docId = docId;
        st.docmimeType = docmimeType;
        st.docHash = docHash;
        st.createdBy =  msg.sender;
        
        status.push(st);
        
       emit EvtContractStatusChanged (contractId,"CourtReferred", st); 
         // set next allowed states
       resetNextStates();
       nextStates[uint(States.Record)] = true;   
       nextStates[uint(States.CourtOrdered)] = true; 

   }       
   function courtOrdered(string docId, string docmimeType, bytes32 docHash)
            public onlyCreator {
        require( 
          nextStates[uint(States.CourtOrdered)],
           "Invalid state, should be after a Court is ordered "
        );
 
        Status memory st;
        st.state = States.CourtOrdered;
        st.tmstamp = now;
        st.docId = docId;
        st.docmimeType = docmimeType;
        st.docHash = docHash;
        st.createdBy =  msg.sender;
        
        status.push(st);
        
       emit EvtContractStatusChanged (contractId,"CourtOrdered", st); 
         // set next allowed states
       resetNextStates();
       nextStates[uint(States.Record)] = true;   
       nextStates[uint(States.EscrowReleased)] = true; 

   }    
    /** 
     * @notice required by marketplace contract 
     * @dev created for compatibility with MktBase.sol Ricardian interface
     * @return Document mine type of the contract & URI of the contract Document
    */
    function contractTemplate() public view  returns (string mime, string uri) {
        mime = status[0].docmimeType;
        uri = status[0].docmimeType;
        return ;
    }
    
    function prevState(States st) internal view returns (bool ok) {
        uint i = skipRecords();
        ok = ( i < status.length && status[i].state == st )? true: false;
        return;
    }
    function skipRecords() internal view returns ( uint ndx ) {
        for(ndx=status.length-1; ndx > 0 ; ndx-- ) {
           if (status[ndx].state == States.Record) 
                continue;
            else
             break;
        }
        return;
    }
    function resetNextStates() internal {
        for(uint i=0; i < uint(States.END); i++) {
            nextStates[i] = false;
        }
    }
} 

