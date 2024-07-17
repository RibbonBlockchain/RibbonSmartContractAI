pragma solidity 0.8.22;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./ribbonVault.sol";
contract worldcoin is ERC20{

 
    constructor()ERC20("worldCoin","wld"){
       _mint(msg.sender,10000000000*10**18);
    }
    
}
contract usdt is ERC20{

 
    constructor()ERC20("usdc","usdc"){
       _mint(msg.sender,10000000000*10**18);
    }
    
}