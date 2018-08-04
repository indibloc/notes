/*
  (c) QzIP Blockchain Technlogy LLP (qzip.business)
  Apache 2.0 License

*/

pragma solidity ^0.4.24;
import "./MktBase.sol";

/** @title B2B Maketplace Catalog 
 *  version v03 - 03-Jul-2018
 */

 
contract MktCatalog is MktBase {

    
    struct ProdSpecAttr {
       string  attrTaxonomyUrn;
       bytes32  i18nId;
       
    }
    struct GeoTag {
        int lat;
        int long;
    }
    struct ProdSpec {
        string    prodSpecUrn;
        bytes32   titleI18nId;
        bytes32   descriptionI18nId;
        ContentAddressedStore   casAddress; // ipfs, couch, swarm or can contain https://...
        Status  status;
        GeoTag geoTag;
        address addedBy;
       // ProdSpecAttr[] prodSpecAttr;
        bytes32[] bundled;  // bundled product/service is a compund product.
         mapping(bytes32 => ProdSpecAttr[] ) prodSpecAttr;
        bool exists;
    }
   
    event EvtProdSpecStatus(
       bytes32 indexed id,
       string indexed urn,
       Status status
    );
    mapping(bytes32 => ProdSpec) public catalog;

    uint offerSeq;
    uint rfqSeq;
    mapping(uint => OpenOffer) public offers;
    mapping(uint => RequestForQuote) public rfq;
    
    constructor( uint ownfee, uint admfee) public MktBase(ownfee, admfee)  {
        
    }
    /*
      @param defaultLang assumes ISO Language Code. http://www.lingoes.net/en/translator/langcode.htm
    */
    function addProductSpec( 
            string    prodSpecUrn, string defaultLang, string title, string description,
            bytes casAddress, string mimeType, CASTypes casType, int lat, int long   
            ) public  onlyAdmin returns (bytes32 catalogId) {
        
        catalogId = keccak256(abi.encodePacked(prodSpecUrn));
        require(!catalog[catalogId].exists, "Product Specs already exists");
        
        bytes32 titileI18n = addI18n(defaultLang, title); 
        bytes32 desc18n = addI18n(defaultLang,description);
    
        
        GeoTag  memory gtag ;
        gtag.lat = lat; gtag.long=long;
        
        ContentAddressedStore memory  cas ;
        cas.casAddress = casAddress;
        cas.mimeType = mimeType;
        cas.casType = casType; 
        
        ProdSpec memory prodSpec;
        
        prodSpec.prodSpecUrn = prodSpecUrn;
        prodSpec.geoTag = gtag;
        prodSpec.titleI18nId = titileI18n;
        prodSpec.descriptionI18nId = desc18n;
        prodSpec.casAddress = cas;
        prodSpec.status = Status.Init ;
        prodSpec.exists = true;
        prodSpec.addedBy = msg.sender;
     
        
        catalog[catalogId] = prodSpec;   
        emit EvtProdSpecStatus(catalogId, prodSpec.prodSpecUrn, prodSpec.status );
        return;
    }
    function addProductSpecAttr(bytes32 prodHsh, string attrTaxonomyUrn, string langCode, string text  ) public  onlyAdmin returns (bytes32 attrId) {
        require(catalog[prodHsh].exists, "Product Specs does NOT exists");
         bytes32 i18nId = addI18n(langCode,text);
        attrId = keccak256(abi.encodePacked(attrTaxonomyUrn)); 
         ProdSpecAttr memory psAttr ;
         psAttr.attrTaxonomyUrn = attrTaxonomyUrn ;
         psAttr.i18nId = i18nId ;
         
         catalog[prodHsh].prodSpecAttr[attrId].push(psAttr);
         
         return;
        
    }
    function bundle(bytes32 parent, bytes32 child) public  onlyAdmin {
        require(
         catalog[parent].exists &&  catalog[child].exists && 
         catalog[parent].addedBy == msg.sender &&
         catalog[child].addedBy == msg.sender ,
         "Not ownner"
        );
        require(
            catalog[parent].status == Status.Init &&
            (catalog[child].status == Status.Init || catalog[child].status == Status.Component ||
             catalog[child].status == Status.Active
            ),
            "Invalid parent or child status"    
        );
        catalog[parent].bundled.push(child);
    }
    function removeProdSpec(bytes32 pid)  public onlyCreator {
        if(catalog[pid].exists) {
            string memory prodSpecUrn = catalog[pid].prodSpecUrn;
            emit EvtProdSpecStatus(pid, prodSpecUrn,Status.Removed );
            delete catalog[pid];
          
        }
        
    }
    function updateProdSpecStatus(bytes32 pid, Status status)  public  onlyAdmin {
        require(status != Status.Init, "Product Spec cannot be reinitialized"); 
        require(
         catalog[pid].exists &&  catalog[pid].addedBy == msg.sender ,
          "Not ownner"
        );
        catalog[pid].status = status;
        emit EvtProdSpecStatus(pid, catalog[pid].prodSpecUrn, catalog[pid].status );  
    }
    
    event OfferAdded(address by, OpenOffer offer, uint offerId, bytes32 prodSpecId, bytes32 ricardianId);
    event OfferRemoved(address by, OpenOffer offer, uint offerId);
    
    function addOpenOffer(OpenOffer offer) public payable fees {
        
        require( parties[msg.sender].exists, "Party not registered");
        Roles role ;
        role = (offer.isBuyOffer())? Roles.Buyer: Roles.Seller ;
        require(hasRole(msg.sender,role), "Not in Role");
        
        bytes32 pid = offer.getProductSpecsId();
        require(catalog[pid].exists, "Product Specs must exist");
        
        bytes32 tmplId = offer.getContractTemplateId();
        require(recardians[tmplId].exists, "ricardian Template must exist");
        
        // distrbute fees
        recardians[tmplId].admin.transfer(adminFee);
        recardians[tmplId].feeSplitContract.transfer(recardians[tmplId].usageFee);
        offers[offerSeq] = offer;
        emit OfferAdded(msg.sender, offer, offerSeq, pid, tmplId);
        offerSeq++;
        
        
    }
    function removeOffer(uint seq) public  onlyAdmin {
        if( offerSeq >= seq) {
          OpenOffer old = offers[seq];
          emit OfferRemoved(msg.sender, old, seq);
          offers[seq] = OpenOffer(address(0));
        }
    }
    event RfqAdded(address by, RequestForQuote offer, uint offerId, bytes32 prodSpecId, bytes32 ricardianId);
    event RfqRemoved(address by, RequestForQuote offer, uint offerId);
    
    function addRfq(RequestForQuote offer) public payable fees {
        
        require( parties[msg.sender].exists, "Party not registered");
        Roles role ;
        role = (offer.isBuyOffer())? Roles.Buyer: Roles.Seller ;
        require(hasRole(msg.sender,role), "Not in Role");
        
        bytes32 pid = offer.getProductSpecsId();
        require(catalog[pid].exists, "Product Specs must exist");
        
        bytes32 tmplId = offer.getContractTemplateId();
        require(recardians[tmplId].exists, "ricardian Template must exist");
        
        // distrbute fees TODO: review the transfer() logic
        recardians[tmplId].admin.transfer(adminFee);
        recardians[tmplId].feeSplitContract.transfer(recardians[tmplId].usageFee);
        rfq[rfqSeq] = offer;
        emit RfqAdded(msg.sender, offer, rfqSeq, pid, tmplId);
        rfqSeq++;
    }
    function removeRfq(uint seq) public  onlyAdmin {
        if(rfqSeq >= seq) {
           RequestForQuote old = rfq[seq];
           emit RfqRemoved(msg.sender, old, seq);
           rfq[seq] = RequestForQuote(address(0));
        }
    }
}


