// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IERC20T {
    function decimals()external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function burn(address account, uint256 value)external;

 
    
}
/// @title RibbonVault
contract  vault is Ownable,EIP712 {
  using SafeERC20 for IERC20;
    bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 deadline)");
        
    IERC20T _Ipaymentcoin;
    IERC20T _Ipointscoin;
    IERC20 private _IpaymentcoinT;
    IERC20 private _IpointscoinT;
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/
    uint public depositFee;
    uint public rate;
    uint public withdrawalFee;
    uint public pointsMin;
    uint public initContractBalancePaymentCoin;
    uint public claimedPaymentCoin;
    uint public TotalfeescollectedPaymentCoin;
    string public vaultName;
    address public admin;
    bool public freezePermit;

    event swap(address indexed user,uint indexed timestamp,uint pointToSwap,uint paymentTokenRecieved,uint _fees);
    event PointsClaimed(address indexed user,uint indexed timestamp,uint amount);
    error ERC2612ExpiredSignature(uint256 deadline);
    error ERC2612InvalidSigner(address signer, address owner);

    mapping (uint8=>bool) sig_v;
    mapping (bytes32=>bool) sig_r;
    mapping (bytes32=>bool) sig_s;
    
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/
    /// @param owner the admin of the contract responsible for offchain signing
    /// @param name the name of the vault
    /// @param pointsaddress the address of the point contract, the offchain virtual points is converted to the points on chain
    /// @param paymentAddress the contract address that the points would be swaped into
    constructor(address owner,string memory name,address paymentAddress,address pointsaddress)Ownable(owner)EIP712(name, "1"){
        vaultName=name;
        depositFee =10;
        rate = 5000;
        _Ipaymentcoin = IERC20T(paymentAddress);
        _IpaymentcoinT = IERC20(paymentAddress);
        _Ipointscoin = IERC20T(pointsaddress);
        _IpointscoinT = IERC20(pointsaddress);
        pointsMin = 10000*10**_Ipointscoin.decimals();
        admin = owner;  
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev used to calcultae amount of the worldcoin token or other payment token to recieve at a specific rate specified
    function checkAmountToRecive(uint pointToSwap)public view returns(uint){
          uint _rate = (pointToSwap * 1*10**_Ipaymentcoin.decimals())/(rate*10**_Ipointscoin.decimals());
          return _rate;
          
    }
    
    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }
    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
    /// @dev update padmin address
    function setAdmin(address _admin)public onlyOwner{
      admin =_admin;
    }
 
    /// @dev update points contract address and worldcoin token or other payment contract address
    function setpaymentTokenAndpoints(address paymentAddress,address pointsaddress)public onlyOwner{
       _Ipaymentcoin = IERC20T(paymentAddress);
       _IpaymentcoinT = IERC20(paymentAddress);
       _Ipointscoin = IERC20T(pointsaddress);
       _IpointscoinT = IERC20(pointsaddress);
     
    }

    /// @dev set depositFee  without decimal 
    function setPaymentDepositfees(uint _fee)public onlyOwner{
       depositFee = _fee;
    }

    /// @dev set withdrawalFee  without decimal 
    function setWithdrawalFee(uint _fee)public onlyOwner{
       withdrawalFee = _fee;
    }

    /// @dev set _rate  without decimal 
    function setRate(uint _rate)public onlyOwner{
         rate = _rate;
    }

    /// @dev set minimum points to swap without decimal
    /// @notice 18 decimal was hardcoded because the points contract is 18 decimal
    function setMinPointsToSWap(uint _pointsMin)public onlyOwner{
         pointsMin = _pointsMin*10**_Ipointscoin.decimals();
    }

    /// @dev used to stop the permit functions to claim point and and swap points to worldcoin token or other payment coin 
    function freezeContract(bool _freeze)public onlyOwner{
     freezePermit = _freeze;
    }

    /// @dev used withdraw fees when a new deposit is address into the contract the computation allows fees to be deducted when new deposit is added 
    /// when no new deposit is added and this function is called it will revert
    function withdrawfees(address feeTakerAddress) public onlyOwner{
       require(feeTakerAddress != address(0),"you are sending to zero address");
       uint contractBalance =_Ipaymentcoin.balanceOf(address(this));
       uint balanceDeposited = (contractBalance + claimedPaymentCoin + TotalfeescollectedPaymentCoin) - initContractBalancePaymentCoin;
       initContractBalancePaymentCoin += balanceDeposited;
       uint _fee = (balanceDeposited*depositFee)/100;
       require(_fee > 0,"no new deposit added");
       TotalfeescollectedPaymentCoin += _fee;
       _IpaymentcoinT.safeTransfer(feeTakerAddress,_fee);
    }

    /// @dev admin signs a user ,amount ,deadline  ofchain and pass the signature  to the user to claim points ,but this is done automatically 
    // when the user clicks the claim button
    function permitClaimPoints(address user,uint amount,uint256 deadline,uint8 v,bytes32 r,bytes32 s)public  {
        require(user != address(0),"you are sending to zero address");
           _permit(user,amount,deadline,v,r,s);
            require(freezePermit==false,"contract freezed");
           require(amount >= pointsMin,"points to claim less than minpoints");
          _IpointscoinT.safeTransfer(user,amount);
       emit   PointsClaimed(user,block.timestamp,amount);
    }
 
    /// @dev admin signs a user ,amount ,deadline  ofchain and pass the signature  to the user to swap points to worldcoin or payment coin ,but this is done automatically 
    // when the user clicks the swap button
    function permitSwapToPaymentCoin(address user,uint pointToSwap,uint256 deadline,uint8 v,bytes32 r,bytes32 s)public {
        require(user != address(0),"you are sending to zero address");
        _permit(user,pointToSwap,deadline,v,r,s);
        require(freezePermit==false,"contract freezed");
        require(_Ipointscoin.balanceOf(user)>= pointToSwap,"not enough points");
        require(pointToSwap >= pointsMin,"points to swap less than minpoints");
        uint amount = checkAmountToRecive(pointToSwap);
        claimedPaymentCoin += amount;
        uint _fee = (amount*withdrawalFee)/100;
        uint amoutAfterFee = amount -_fee;
        _Ipointscoin.burn(user,pointToSwap);
        _IpaymentcoinT.safeTransfer(user,amoutAfterFee);
        _IpaymentcoinT.safeTransfer(msg.sender,_fee);
        emit swap(user,block.timestamp,pointToSwap,amoutAfterFee,_fee);
    }

   
    /// @dev this is used to withdraw any asset stuck in the contract by mistake by only the admin
    function emergencyWithdraw(address _tokenAddress,address _to,uint _amount )public onlyOwner{
        require(_tokenAddress != address(0),"you are sending to zero address");
        require(_to != address(0),"you are sending to zero address");
        require(_amount > 0,"cant send zero amount");
        IERC20T(_tokenAddress).transfer(_to,_amount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev _permit is used for offchain signature verification of the admin
    function _permit(
        address user,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
       /// used to prevent signature replay to avoid signature been used more once
        require(sig_v[v]==false || sig_r[r] == false || sig_s[s]==false,"sig used");
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, admin, user, value, deadline)); 
        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != admin) {
            revert ERC2612InvalidSigner(signer, admin);
        }
        sig_v[v]=true;
        sig_r[r]=true;
        sig_s[s]=true;    
    }
 
}