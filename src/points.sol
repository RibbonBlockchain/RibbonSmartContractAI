// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.22;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ribbonVault.sol";

/// @title RibbonVault
contract points is ERC20,Ownable{
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/
    struct vaultId{
        address vaultAdrress;
        string  name;  
    }
    uint public counterId=1;
    address public vaultAdmin;
    mapping (string =>bool) nameVault;
    mapping (uint=>vaultId)public vaultIdentifcation;
    mapping (address=>bool)approveToBurn;
 
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/
    /// @param addvaultadmin the admin address of the contract for creating vault only the admin can call this function
    constructor(address addvaultadmin)ERC20("Points","PNT")Ownable(msg.sender){
       _mint(msg.sender,6000000000*10**18);
       _mint(address(this),4000000000*10**18);
        vaultAdmin=addvaultadmin;
    
    }

    /*//////////////////////////////////////////////////////////////////////////
                         PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

     /// @dev used to set vault admin address
    function setVAultAdmin(address addvaultadmin)public onlyOwner{
        vaultAdmin=addvaultadmin;  
    }

    /// @dev used to set vault addresses responsible for burning points when swapped to world coin or other payment token
    function setApproveToburn(address approvedAdd, bool _approve)external onlyOwner {
              _setApproveToburn(approvedAdd, _approve);
    }

    /// @dev used to mint new points token to be supplied to the vault
    function mint(address add,uint amount)public onlyOwner{
        _mint(add,amount);
    }
    /// @dev used to transfer points token to vault contract from the address(this) can only be called by admin
    function TranferToVault(address Vaultadd,uint amount)public {
         require(msg.sender==vaultAdmin,"not approved");
        _TranferToVault(Vaultadd,amount);
    }

    /// @dev used to burn point token by approved vault address
    function burn(address account, uint256 value)public {
        require(approveToBurn[msg.sender] == true, "you are not approved to burn");
        _burn( account, value);
 
    } 
    /// @dev used to create vault for different partners
    function createVault(string memory vaultName,address vaultOwner,address paymentAddress,uint pointsAmountForVault)public  returns(bool){
        require(msg.sender==vaultAdmin,"not approved");
         vaultId storage _vaultid =  vaultIdentifcation[counterId];
         require(nameVault[vaultName]==false, "name taken");
         nameVault[vaultName]= true;
          vault _vault =new vault(vaultOwner,vaultName,paymentAddress,address(this));
         _vaultid.vaultAdrress =address(_vault);
         _vaultid.name=vaultName;
        _TranferToVault(address(_vault),pointsAmountForVault);
         counterId++;
         _setApproveToburn(address(_vault) , true);
         return true;
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _TranferToVault(address Vaultadd,uint amount)internal {
        _approve(address(this),msg.sender,amount);
        transferFrom(address(this), Vaultadd, amount);
    }

    function _setApproveToburn(address approvedAdd, bool _approve)internal {
              approveToBurn[approvedAdd]=_approve;
    }

    
}