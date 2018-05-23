/*
  (c) QzIP Blockchain Technlogy LLP (qzip.business)
  Apache 2.0 License
  
  v001
*/

pragma solidity ^0.4.0;

contract Marketplace {
    
    enum Roles { Buyer, Seller, EscrowProvider, Arbitrator, Regulator}
    
    enum Status {Active, Dormant, Expired, Suspended}
    
    struct Participant {
        string partyID; // short  unique id
        address partyAddress;
        bytes partyOpenPGPCertificate;
        Roles[] roles;
        Status status;
    }
    
    struct Catalog {
        string   casAddressURI; // ipfs, couch, swarm or can contain https://...
        Status  status;
        bytes   detachedPGPSignature;
    }
    
    bytes   creatorOpenPGPCertificate; // making this public raises the gas price to infinite.
    Catalog  catalog;

    
    
}

