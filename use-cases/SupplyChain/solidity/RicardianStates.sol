pragma solidity ^0.4.24;
//pragma experimental ABIEncoderV2;

/** 
 * @title Alo Agri Onion Contract (optimized version)
 * @author Ashish Banerjee (ashish@qzip.in)
 * @notice Ricardian Smart Contract (annonymized)
 * @dev  Assummes that buyer and sellers are not part of blockchain network.
 * version v04 - 02-July-2018
 * 
 * This version assumes that the buyer and seller both do not have Key pair.
 * for these entities annonymous id are used.
 * 
 * Previous Contract AloAgriOnion.sol exceeds the data limit of 32KB
 * https://ethereum.stackexchange.com/questions/46541/is-there-a-maximum-number-of-public-functions-in-a-contract/46612#46612
 * 
 *
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
 *
 * 02-jul-18: changed event parameters to exclude passing struct, as solc was generatin Tuple type. 
 *            Tuple type is unsupported by abigen in Version: 1.8.6-stable.
 * 02-jul-18 : Optimizing the code to fit into 32KB limit.
 */
 
 contract RicardianStates {
     
    mapping(string => bool) nextStates; // 
    struct Status {
        string  state;
        uint   tmstamp;
        string docId;
        string docmimeType;
        bytes32 docHash;
        address createdBy;
        
    }
    address public creator ;
    string  public contractId ;
    string public contractDocMine;
    bytes32 public contractHash;
    
    Status[] public status;  
    mapping(string => bool) roles;
    mapping(string =>  mapping(string => bool)) stateRoles;
    string[] states;
    mapping(string => mapping(string => bool)) stateMach;
    mapping(address => Party) partyAddr;
    mapping(string => Party) partyIdz;
    
    struct Party {
        string partyID; // anonymized uuid
        string role; // one party can have a single role.
        address who; // for non B2B party it will be address(0)
    }
    event EvtContractStatusChanged (
        string  contractId,
        string  statusType,   // enum are not visible outside solidity
        uint tmstamp,
        string docId,
        string docmimeType,
        bytes32 docHash,
        address createdBy
    
    );
    modifier onlyCreator() { // Modifier
        require(
            msg.sender == creator,
            "Only creator can call this."
        );
        _;  // function content being modified is placed here
    }
     constructor(string contract_id, 
                string contractMimeType, bytes32 contract_Hash 
               ) public {
        creator = msg.sender;
       contractDocMine = contractMimeType;
       contractHash = contract_Hash;
       contractId = contract_id;            
    }
    function addRole(string role) public onlyCreator {
        roles[role] = true;
        
    }
    function addParty(string partyId, string partyRole, address addr)  public onlyCreator {
        Party memory pty ;
        pty.partyID = partyId;
        pty.role = partyRole;
        pty.who = addr;
        if(addr != address(0)) 
           partyAddr[addr] = pty;
        partyIdz[partyId]   = pty;
    }
    function addState(string st)  public onlyCreator {
        states.push(st);
    }
    function addStateRole(string st, string rol) public onlyCreator {
        stateRoles[st][rol] = true;
    }
    // multiple calls
    function addStateElement(string st, string nxtSt)  public onlyCreator {
        stateMach[st][nxtSt] = true;
        
    }
    /**
     * @dev WARNING: the state tables should be created with care
     */
    function changeState(string stat, string docId,string  docmimeType ,
        bytes32 docHash) public {
           
        require (  
            ((nextStates[stat] && status.length > 0 ) &&
            stateRoles[status[status.length-1].state][partyAddr[msg.sender].role] &&
            (msg.sender == creator ||  partyAddr[msg.sender].who != address(0))),
            "Party not in role"
        );    
        Status memory sts;
        sts.state = stat;
        sts.tmstamp = now;
        sts.docId = docId;
        sts.docmimeType = docmimeType;
        sts.docHash = docHash;
        sts.createdBy = msg.sender;
        
        status.push(sts);
        
       emit EvtContractStatusChanged (contractId, stat, 
       sts.tmstamp, sts.docId, sts.docmimeType, sts.docHash, sts.createdBy       
       ); 
       setNextStates(stat); 
    }
    function setNextStates(string st) internal {
        for(uint i=0; i < states.length; i++) {
            nextStates[states[i]] = stateMach[st][states[i]];
        }
    }    
 }
 

