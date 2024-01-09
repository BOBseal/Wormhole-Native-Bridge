*** WORMHOLE BASED BRIDGE CONTRACT - BASIC VERSION ***

IMPORTANT => 

require OpenZeppelin < 5.0.0 

post deployment endpoint contracts must be sent to allow crosscommunication between bridge instances on each chain for each chain

FEATURES :

: Bridge Native Token To/from EVM.
: Bridge Erc-20/xAssets to/from EVM
: Auto-Claiming of Assets to selected reciever at time of bridgeIn



How to use :

Scenario 1: When Bridging Native Token 

  a) Call ```function quoteCrossChainDeposit(
        uint16 targetChain,
        uint256 amt ,
        uint256 gasUnits
    ) public view returns (uint256 cost)``` 

  targetChain => chainId (Wormhole Id) of chain to send funds to 
  amt => amount of Native Token to be sent (set 0 in case of erc20 -- base gas 200k)
  gasUnits => Gas Units of DestChain needed to execute the receiever logic 

  Returns => Cost === Total cost in Native token needed to be sent with bridge function to cover all costs


  b) In the function ```bridgeEther(uint16 targetChain,address targetHelloToken,address recipient,uint256 amount,uint256 dstGas) ```
      
        targetChain => chain to recieve
        targetHelloToken => TargetChain Bridge Contract Instance
        recipient => address on dest chain to recieve funds to
        amount => amount of ether in wei 
        dstGas => gas Units in dest chain needed for execution of logic

Scenario 2: For erc20 --- 

  Follow same procedure but replace the amt in quote function to 0 , and in bridgeErc20 function amount => erc20 token amount instead of ether



FEEL FREE TO USE IT FOR LEARNING PURPOSES , AND IF YOU LIKE PLEASE DO LIKE THE REPO.

SUPPORT ME BY DONATING AT : 

Evm : 0xe34CC9661070B7A68F5F5d6eC6a613D8c2F21265
