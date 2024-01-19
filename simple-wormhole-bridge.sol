// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./src/Utils.sol";
import {IWETH} from "./src/interfaces/IWETH.sol";
import {TokenBase, TokenReceiver, TokenSender} from "./src/TokenBase.sol";
import "./src/interfaces/IWormholeReceiver.sol";
import "./src/interfaces/IWormholeRelayer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BridgeV1 is TokenSender , TokenReceiver, Ownable{

//    mapping(address => USER) internal userData;
    mapping(address=>mapping(bytes32=> bool)) public delivered;
    mapping(uint16 => mapping(address => bool)) public endpoints;

    constructor(
        address _wormholeRelayer,
        address _tokenBridge,
        address _wormhole//,
    
    )Ownable(msg.sender) TokenBase(_wormholeRelayer, _tokenBridge, _wormhole) {
        
    }
    // allow contract instances must from src chains
    function setEndpointForRecieve(uint16 ch , address Address) public onlyOwner {
        endpoints[ch][Address] = true;
    }

    function quoteCrossChainDeposit(
        uint16 targetChain,
        uint256 amt ,
        uint256 gasUnits
    ) public view returns (uint256 cost) {
        uint256 deliveryCost;
        //f = fee;
        (deliveryCost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            amt,
            gasUnits
        );
        // Total cost: delivery cost + cost of publishing the 'sending token' wormhole message + dst fee
        cost = deliveryCost + wormhole.messageFee();
    }

    function bridgeErc20(
        uint16 targetChain,
        address targetHelloToken,
        address recipient,
        uint256 amount,
        address token,
        uint256 dstGas
    ) public payable {
        (uint256 cost) = quoteCrossChainDeposit(targetChain, 0, dstGas);
        require(
            msg.value >= cost,
            "msg.value must be quoteCrossChainDeposit(targetChain)"
        );
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        bytes memory payload = abi.encode(recipient, uint8(1) , 0);
        sendTokenWithPayloadToEvm(
            targetChain,
            targetHelloToken, // address (on targetChain) to send token and payload to
            payload,
            0, // receiver value
            dstGas, // gas units
            token, // address of IERC20 token contract
            amount // amount
        );
    }

    function bridgeEther(
        uint16 targetChain,
        address targetHelloToken,
        address recipient,
        uint256 amount
        ,uint256 dstGas
    ) public payable {
        (uint256 cost) = quoteCrossChainDeposit(targetChain, amount,dstGas);
        require(
            msg.value >= cost,
            "mismatch in fee"
        );
        IWETH wrappedNativeToken = tokenBridge.WETH();
        bytes memory payload = abi.encode(recipient ,uint8(0), amount);
        sendTokenWithPayloadToEvm(
            targetChain,
            targetHelloToken, // address (on targetChain) to send token and payload to
            payload, // data
            amount, // receiver value 
            dstGas, // gas units
            address(wrappedNativeToken), // address of IERC20 token contract
            0 // amount 0 as native send as gas drop
        );
    }

    function receivePayloadAndTokens(
        bytes memory payload,
        TokenReceived[] memory receivedTokens,
        bytes32 srcA, // sourceAddress
        uint16 ch,
        bytes32 dh// deliveryHash
    ) internal override onlyWormholeRelayer {
        require(receivedTokens.length == 1);
        require(endpoints[ch][fromWormholeFormat(srcA)] == true); // to prevent any contract to mock data and drain fee or other balances
        (
            address recipient,
            uint8 type_,
            uint256 amt
        ) = abi.decode(payload, (address, uint8, uint256));

        require(delivered[recipient][dh] == false); // to prevent reentrancy and spoofing attacks
        address tokenAddress = receivedTokens[0].tokenAddress;
        // type handling for native and erc20
        if(type_ == uint8(0)) { 
            delivered[recipient][dh] = true;
            payable(recipient).transfer(amt); 
        } else  if(type_ == uint8(1)){
            uint256 amount = receivedTokens[0].amount;
            delivered[recipient][dh] = true;
            IERC20(tokenAddress).transfer(recipient,amount);
        }
    }

}
