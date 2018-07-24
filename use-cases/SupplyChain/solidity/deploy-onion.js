// http://web3js.readthedocs.io/en/1.0/web3-eth-contract.html

 Web3 = require('web3');
 var rpcAddr = "http://localhost:8545";
 web3 = new Web3(rpcAddr);
 web3.setProvider(rpcAddr);

var contract_id = "aloagri-03-jul18-1112"; /* var of type string here */ ;
var buyer = "byr-x32";/* var of type string here */ ;
var seller = "slr-y-34"; /* var of type string here */ ;
var contractMimeType = "pdf"; /* var of type string here */ ;
var contract_Hash =  "0x522e1b1f273b31ad03b890497677127b6fd535929cfee5869bb533cac261ad40";

// https://nodejs.org/api/fs.html
const fs = require('fs');

var abi = fs.readFileSync('./AloAgriOnion.abi', 'utf8');
var data = fs.readFileSync('./AloAgriOnion.bin');

var obj = JSON.parse(abi);

var aloagrionionContract = new web3.eth.Contract(obj);

var addr = "ade4efd6706af99dcd8dcacd32d53ea397af11aa";

var aloagrionion = aloagrionionContract.deploy(
{ data: '0x' + data,
  arguments: [
  contract_id,
   buyer,
   seller,
   contractMimeType,
   contract_Hash
  ] 
}
);

console.log("Deployed");
console.log(web3.currentProvider);



aloagrionion.send({
    from: addr,
    gas: 4712388,
    gasPrice: '18000000000'
},  function(error, transactionHash){if(error != null) console.log("sending "+ error + " txnHash:"+transactionHash); })
.on('error', function(error){ console.log( error + "]] post call");})
.on('transactionHash', function(transactionHash){ console.log(transactionHash)})
.on('receipt', function(receipt){
   console.log(receipt.contractAddress) // contains the new contract address
})
.on('confirmation', function(confirmationNumber, receipt){ console.log(confirmationNumber, receipt) })
.then(function(newContractInstance){
    console.log(newContractInstance.options.address) // instance with the new contract address
}).catch(function(error) {console.log(error);});



