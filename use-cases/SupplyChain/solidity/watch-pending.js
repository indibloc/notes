 Web3 = require('web3');
 var rpcAddr = "http://localhost:8545";
 web3 = new Web3(rpcAddr);
 web3.setProvider(rpcAddr);

web3.eth.filter("pending").watch(
    function(error,result){
        if (!error) {
            console.log(result);
        }
    }
)


