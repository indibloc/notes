/*
  (c) QzIP Blockchain Technlogy LLP (qzip.business)
  Apache 2.0 License

*/

pragma solidity ^0.4.24;
//pragma experimental ABIEncoderV2;

/** @title B2B Maketplace Base 
 *  version v02 - 03-June-2018
 */
 
 interface OpenOffer {
        function isBuyOffer() external returns (bool);
        function getOwner() external returns (address owner);
        function isValid() external returns (bool);
        function validTil() external returns (uint);
        function getProductSpecsId() external returns (bytes32); 
        function offerValue() external returns (string currency, uint amount);
        function getContractTemplateId() external returns (bytes32);
        function acceptOffer() external returns (Ricardian);   // called from DApp
    }
interface RequestForQuote {
        function isBuyOffer() external returns (bool);
        function getOwner() external returns (address owner);
        function isValid() external returns (bool);
        function validTil() external returns (uint);
        function getProductSpecsId() external returns (bytes32); 

        function getContractTemplateId() external returns (bytes32); 
        
        function allowOpenQuote() external returns (bool);
        function quote(string currency, uint amount, uint validity) external returns (bytes32 refId); 

        function allowSealedQuote() external returns (bool);
        // Signcrypted value of ({string currency, uint amount, uint validity}, bytes nonce)
        function sealedQuote() external returns (bytes32 refId); 
    
        function isAwardee() external returns (bool awardee, bytes32 refId); //  if(msg.sender == awardee)
        function acceptAward(bytes32 refId) external returns (Ricardian);   // called from DApp require(msg.sender == awardee)
}
interface Ricardian {
    function contractTemplate() external  returns (string mime, string uri);
}     
contract MktBase {
    
    enum Roles { Buyer, Seller, EscrowProvider, Arbitrator, Regulator}
    enum CASTypes {Swarm, IPFS, CounchDb, CloudURL}
    enum Status {Init, Active, Dormant, Expired, Suspended, Component, Removed}
    enum HashType {Sha3, Sha256, Sha512, Keccak256}
    struct Participant {
        string partyID; // short  unique id
        address partyAddress;
        bytes partyOpenPGPCertificate;
        Status status;
        bool exists;  // there is no way to check if mapping element exists
        Roles[] roles;
    }
    struct ContentAddressedStore {
        bytes casAddress;
        string mimeType;
        CASTypes casType;
    }
    
    struct Hash {
        HashType hashType;
        bytes  hashVal;
    }
    struct ArbitrationCharge {
        address arbitrator;
        string  currency;   // ISO code  https://en.wikipedia.org/wiki/ISO_4217
        uint    endrosementCharge;
        uint    disputeResolutionCharge;
        ContentAddressedStore terms;
        bool withdrawn;
    }
    event EvtEndrosed(bytes32 recardianId, address arbitrator);
    event EvtEndroserWithdrawn(bytes32 recardianId, address arbitrator, address by);
    
    struct RicardianContractTemplate {
        string mime;
        string uri;
        Status status;
        bool exists;  // there is no way to check if mapping element exists
        uint usageFee;
        address feeSplitContract;
        ArbitrationCharge[] endrosers;
        address redFlag;  // only Regulator can raise flag
        address admin;
    }
    event EvtRicardianStatus(
        bytes32 indexed id,
        string uri,
        Status status
    ); 
    mapping(address => Participant) public parties;
    mapping(address => bool) public admins;
    mapping(bytes32 => RicardianContractTemplate) public  recardians;
    
    bytes   public creatorOpenPGPCertificate;
    address creator;
    
    // i18n Code/Id => lang code => text 
    mapping(bytes32 => mapping(bytes32 => string)) public i18nDict;

    
    constructor(bytes pgpCert, uint ownfee, uint admfee) public {
        creator = msg.sender; 
        creatorOpenPGPCertificate = pgpCert;
        ownerFee = ownfee;
        adminFee = admfee ;
    }
    
    uint public ownerFee;
    uint public adminFee;
    
    
    modifier fees() {
       require (
           msg.value >= (ownerFee + adminFee),
           "Service fees inadequately funded"
        );    
        
        _;
    }
   
    modifier onlyCreator() { // Modifier
        require(
            msg.sender == creator,
            "Only creator can call this."
        );
        _;  // function content being modified is placed here
    }
    
    modifier onlyAdmin() { // Modifier
        require(
            admins[msg.sender] ||  msg.sender == creator,
            "Only admin can call this."
        );
        _;  // function content being modified is placed here
    }
    function resetFees(uint ownfee, uint admfee) public onlyCreator {
        ownerFee = ownfee;
        adminFee = admfee ;        
    }
    function addAdmin(address admin) public onlyCreator {
        admins[admin] = true;
          
    }
    function removeAdmin(address admin) public onlyCreator {
        delete admins[admin];
        
    }
 
    function addRicardian (
        string uri, string mime, uint usageFee, address feeSplitContract 
        ) public onlyAdmin returns (bytes32 recardianId) {
       recardianId = keccak256(uri);
       require(
           !recardians[recardianId].exists,
           "Ricardian exists"
           );
        RicardianContractTemplate  ric;
        ric.uri = uri;
        ric.exists = true;
        ric.status = Status.Init;
        ric.admin = msg.sender;
        ric.usageFee = usageFee;
        ric.feeSplitContract = feeSplitContract; 
        recardians[recardianId] = ric;
        emit EvtRicardianStatus(recardianId,  ric.uri, ric.status);
        return;
    }
    function updateRicardianStatus(bytes32 recardianId, Status status ) public onlyAdmin {
        require(recardians[recardianId].exists, "Ricardian Does not exist");
        require(
           msg.sender == creator || msg.sender ==  recardians[recardianId].admin,
           "Invalid ownership"
        );
        require(status != Status.Init, "Cannot reset to init state");
        recardians[recardianId].status = status;
        emit EvtRicardianStatus(recardianId,  recardians[recardianId].uri, recardians[recardianId].status);
    }
    function removeRicardian(bytes32 recardianId) public onlyCreator {
        if (recardians[recardianId].exists) {
            emit EvtRicardianStatus(recardianId,  recardians[recardianId].uri, Status.Removed);
            delete recardians[recardianId];
        }
    }
    
     
    /*
        @dev To register as an endroser; the Aribitrator pays fee to stakeholders
        The endroser then gets a fee if anyone selects them as an arbitrator.
    */
    function endrose(
        bytes32 recardianId,
        string  currency,  uint    endrosementCharge,
        uint    disputeResolutionCharge, 
        bytes termsCasAddr, string termsMime, CASTypes termsCasType
    ) public payable fees {
        require(recardians[recardianId].exists, "Ricardian Does not exist");
        require(msg.value >= (ownerFee + adminFee + recardians[recardianId].usageFee) , "");
        require(hasRole(msg.sender, Roles.Arbitrator), "Not an Arbitrator");
        
        bool hasEndrosed = false;
      // = recardians[recardianId].endrosers;
        for(uint i=0; i < recardians[recardianId].endrosers.length; i++) {
            if(recardians[recardianId].endrosers[i].arbitrator == msg.sender) {
                hasEndrosed = true;
                recardians[recardianId].endrosers[i].currency = currency;
                recardians[recardianId].endrosers[i].withdrawn = false;
                recardians[recardianId].endrosers[i].endrosementCharge = endrosementCharge;
                recardians[recardianId].endrosers[i].disputeResolutionCharge = disputeResolutionCharge;
                
                recardians[recardianId].endrosers[i].terms.casAddress = termsCasAddr;
                recardians[recardianId].endrosers[i].terms.mimeType = termsMime;
                recardians[recardianId].endrosers[i].terms.casType = termsCasType;
            }
        }
        if(!hasEndrosed) {
             ArbitrationCharge memory arbit;

                arbit.currency = currency;
                arbit.withdrawn = false;
                arbit.endrosementCharge = endrosementCharge;
                arbit.disputeResolutionCharge = disputeResolutionCharge;
                
                arbit.terms.casAddress = termsCasAddr;
                arbit.terms.mimeType = termsMime;
                arbit.terms.casType = termsCasType;     
                recardians[recardianId].endrosers.push(arbit);
        }
        // distrbute fees
        recardians[recardianId].admin.transfer(adminFee);
        recardians[recardianId].feeSplitContract.transfer(recardians[recardianId].usageFee);
        emit EvtEndrosed(recardianId, msg.sender);
    }
    function withdrawEndrosement(bytes32 recardianId ) public {
         require(recardians[recardianId].exists, "Ricardian Does not exist");
         require(hasRole(msg.sender, Roles.Arbitrator), "Not an Arbitrator");
         // find the endroser
       for(uint i=0; i < recardians[recardianId].endrosers.length; i++) {
            if(recardians[recardianId].endrosers[i].arbitrator == msg.sender) 
                recardians[recardianId].endrosers[i].withdrawn = true;
               
        }       
        emit EvtEndroserWithdrawn(recardianId, msg.sender, msg.sender);
    
    }
    function withdrawEndroser(bytes32 recardianId, address erdroser) public onlyAdmin {
        require(recardians[recardianId].exists, "Ricardian Does not exist");
       for(uint i=0; i < recardians[recardianId].endrosers.length; i++) {
            if(recardians[recardianId].endrosers[i].arbitrator == erdroser) 
                recardians[recardianId].endrosers[i].withdrawn = true;
               
        }     
        emit EvtEndroserWithdrawn(recardianId, erdroser, msg.sender);
    }
    
    function raiseFlag(bytes32 recardianId) public {
        require(hasRole(msg.sender, Roles.Regulator), "Not a Regulator");
        require(recardians[recardianId].exists, "Ricardian Does not exist");
        recardians[recardianId].status = Status.Suspended;
        recardians[recardianId].redFlag = msg.sender;
        emit EvtRicardianStatus(recardianId,  recardians[recardianId].uri, recardians[recardianId].status);
    }
    function addParty(
        string partyID, // short  unique id
        address partyAddress,
        bytes partyOpenPGPCertificate,
        Status status,
        Roles defaultRole
    ) public onlyAdmin {
        require (
            ! parties[partyAddress].exists,
            "Party already exists"
            
            );
        Participant memory party ;
        party.partyID = partyID;
        party.partyAddress = partyAddress;
        party.partyOpenPGPCertificate = partyOpenPGPCertificate;
        party.status = status;
        party.exists = true;
        party.roles = new  Roles[](1);
        party.roles[0] = defaultRole;
        
        parties[partyAddress] = party;
    
        
    }
    function addRole(address partyAddress, Roles role )  public onlyAdmin {
          require (
            parties[partyAddress].exists,
            "Party does not exists"
            );      
             parties[partyAddress].roles.push(role);
    }
    function hasRole(address partyAddress, Roles role )   returns (bool ok) {
        ok = false;
        if( parties[partyAddress].exists) {
            if(parties[partyAddress].roles.length > 0) {
                for(uint i=0; i < parties[partyAddress].roles.length; i++)
                  if(parties[partyAddress].roles[i] == role) {
                      ok = true;
                      break;
                  }
                     
            }
        }
        return ;
    }
    
    function addI18n(string langcode, string text) public  onlyAdmin returns (bytes32 catalogId) {
       bytes32 lid = keccak256(langcode);
       catalogId = keccak256(lid, text ); 
       i18nDict[catalogId][lid] = text;
       return;
    }
}

