// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/Ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IRibbon} from "./IRibbon.sol";
import {IWETH} from "./IWETH.sol";
import {BondingCurve} from "./BondingCurve.sol";
import "./IUNI.sol";



contract Ribbon is  IRibbon,  Initializable, ERC20Upgradeable, ReentrancyGuardUpgradeable {
    uint256 public constant MAX_TOTAL_SUPPLY = 1_000_000_000e18; // 1B tokens
    uint256 public constant PRIMARY_MARKET_SUPPLY = 800_000_000e18; // 800M tokens
    uint256 public constant SECONDARY_MARKET_SUPPLY = 200_000_000e18; // 200M tokens
    uint256 public constant TOTAL_FEE_BPS = 100; // 1%
    uint256 public constant TOKEN_CREATOR_FEE_BPS = 5000; // 50% (of TOTAL_FEE_BPS)
    uint256 public constant PROTOCOL_FEE_BPS = 2000; // 20% (of TOTAL_FEE_BPS)
    uint256 public constant PLATFORM_REFERRER_FEE_BPS = 1500; // 15% (of TOTAL_FEE_BPS)
    uint256 public constant ORDER_REFERRER_FEE_BPS = 1500; // 15% (of TOTAL_FEE_BPS)
    uint256 public constant MIN_ORDER_SIZE = 0.0000001 ether;
   
    address public immutable protocolFeeRecipient;
    address public immutable protocolRewards;
    address public immutable WETH;
    BondingCurve public bondingCurve;
    MarketType public marketType;
    address public platformReferrer;
    address public poolAddress;
    address public tokenCreator;
    string public tokenURI;
    uint256 public lpTokenId;
    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    string public posturl;
    address public protocolfeeAddress=0xBD53A5dF1fD60aBa402cF346eE07Ed8B058c17d0;

     

    /// @notice Initializes a new Wow token
    /// @param _tokenCreator The address of the token creator
    /// @param _platformReferrer The address of the platform referrer
    /// @param _bondingCurve The address of the bonding curve module
 
    /// @param _name The token name
    /// @param _symbol The token symbol
      function initialize(
        address _tokenCreator,
        address _bondingCurve,
      
        string memory _name,
        string memory _symbol,
        string memory _posturl
    )  public payable initializer {
        // Validate the creation parameters
        if (_tokenCreator == address(0)) revert AddressZero();
        if (_bondingCurve == address(0)) revert AddressZero();
        // if (_platformReferrer == address(0)) {
        //     _platformReferrer = protocolFeeRecipient;
        // }

        // Initialize base contract state
        __ERC20_init(_name, _symbol);
        __ReentrancyGuard_init();

        // Initialize token and market state
        marketType = MarketType.BONDING_CURVE;
        // platformReferrer = _platformReferrer;
        tokenCreator = _tokenCreator;
        // tokenURI = _tokenURI;
        bondingCurve = BondingCurve(_bondingCurve);
        posturl = _posturl;
       

        // Execute the initial buy order if any ETH was sent
        if (msg.value > 0) {
            buy(_tokenCreator, _tokenCreator, MarketType.BONDING_CURVE, 0);
        }
    }

   

    // function posturlC()public view returns(string memory) { 
    //     return posturl;
    // }
        

    /// @notice Purchases tokens using ETH, either from the bonding curve or Uniswap V3 pool
    /// @param recipient The address to receive the purchased tokens
    /// @param refundRecipient The address to receive any excess ETH

    /// @param expectedMarketType The expected market type (0 = BONDING_CURVE, 1 = UNISWAP_POOL)
    /// @param minOrderSize The minimum tokens to prevent slippage
   
    function buy(
        address recipient,
        address refundRecipient,
        MarketType expectedMarketType,
        uint256 minOrderSize
    ) public payable nonReentrant returns (uint256) {
        // Ensure the market type is expected
        if (marketType != expectedMarketType) revert InvalidMarketType();

        // Ensure the order size is greater than the minimum order size
        if (msg.value < MIN_ORDER_SIZE) revert EthAmountTooSmall();

        // Ensure the recipient is not the zero address
        if (recipient == address(0)) revert AddressZero();

        // Initialize variables to store the total cost, true order size, fee, and refund if applicable
        uint256 totalCost;
        uint256 trueOrderSize;
        uint256 fee;
        uint256 refund;

  

        if (marketType == MarketType.BONDING_CURVE) {
            // Used to determine if the market should graduate
            bool shouldGraduateMarket;

            // Validate the order data
            (totalCost, trueOrderSize, fee, refund, shouldGraduateMarket) = _validateBondingCurveBuy(minOrderSize);

            // Mint the tokens to the recipient
            _mint(recipient, trueOrderSize);

            // Handle the fees
            // _disperseFees(fee, orderReferrer);
            (bool successpro, ) = protocolfeeAddress.call{value: fee}("");
            if (!successpro) revert EthTransferFailed();

            // Refund any excess ETH
            if (refund > 0) {
                (bool success, ) = refundRecipient.call{value: refund}("");
                if (!success) revert EthTransferFailed();
            }

             if (shouldGraduateMarket) {
                _graduateMarket();
                marketType = MarketType.UNISWAP_POOL;
            }

            // if (dd==true){
            //     _graduateMarket();
            //      marketType = MarketType.UNISWAP_POOL;

            // }

       
        }

       

        return trueOrderSize;
    }

    /// @notice Sells tokens for ETH, either to the bonding curve or Uniswap V3 pool
    /// @param tokensToSell The number of tokens to sell
    /// @param recipient The address to receive the ETH payout
    /// @param expectedMarketType The expected market type (0 = BONDING_CURVE, 1 = UNISWAP_POOL)
    /// @param minPayoutSize The minimum ETH payout to prevent slippage
    function sell(
        uint256 tokensToSell,
        address recipient,
        MarketType expectedMarketType,
        uint256 minPayoutSize
    ) external nonReentrant returns (uint256) {
        // Ensure the market type is expected
        if (marketType != expectedMarketType) revert InvalidMarketType();

        // Ensure the sender has enough liquidity to sell
        if (tokensToSell > balanceOf(msg.sender)) revert InsufficientLiquidity();

        // Ensure the recipient is not the zero address
        if (recipient == address(0)) revert AddressZero();

        // Initialize the true payout size
        uint256 truePayoutSize;

      

        if (marketType == MarketType.BONDING_CURVE) {
            truePayoutSize = _handleBondingCurveSell(tokensToSell, minPayoutSize);
        }

        // Calculate the fee
        uint256 fee = _calculateFee(truePayoutSize, TOTAL_FEE_BPS);

        // Calculate the payout after the fee
        uint256 payoutAfterFee = truePayoutSize - fee;

        // Handle the fees
        // _disperseFees(fee, orderReferrer);
        (bool successpro, ) = protocolfeeAddress.call{value: fee}("");
            if (!successpro) revert EthTransferFailed();

        // Send the payout to the recipient
        (bool success, ) = recipient.call{value: payoutAfterFee}("");
        if (!success) revert EthTransferFailed();

       

        return truePayoutSize;
    }


    function changeprotocofeeaddress(address add)public {
         protocolfeeAddress = add;
    }

    /// @notice Burns tokens after the market has graduated to Uniswap V3
    /// @param tokensToBurn The number of tokens to burn
    function burn(uint256 tokensToBurn) external {
        if (marketType == MarketType.BONDING_CURVE) revert MarketNotGraduated();

        _burn(msg.sender, tokensToBurn);
    }

    /// @notice Force claim any accrued secondary rewards from the market's liquidity position.
    /// @dev This function is a fallback, secondary rewards will be claimed automatically on each buy and sell.
    /// @param pushEthRewards Whether to push the ETH directly to the recipients.
  

    /// @notice Returns current market type and address
    function state() external view returns (MarketState memory) {
        return MarketState({marketType: marketType, marketAddress: marketType == MarketType.BONDING_CURVE ? address(this) : poolAddress});
    }

    /// @notice The number of tokens that can be bought from a given amount of ETH.
    ///         This will revert if the market has graduated to the Uniswap V3 pool.
    function getEthBuyQuote(uint256 ethOrderSize) public view returns (uint256) {
        if (marketType == MarketType.UNISWAP_POOL) revert MarketAlreadyGraduated();

        return bondingCurve.getEthBuyQuote(totalSupply(), ethOrderSize);
    }

    /// @notice The number of tokens for selling a given amount of ETH.
    ///         This will revert if the market has graduated to the Uniswap V3 pool.
    function getEthSellQuote(uint256 ethOrderSize) public view returns (uint256) {
        if (marketType == MarketType.UNISWAP_POOL) revert MarketAlreadyGraduated();

        return bondingCurve.getEthSellQuote(totalSupply(), ethOrderSize);
    }

    /// @notice The amount of ETH needed to buy a given number of tokens.
    ///         This will revert if the market has graduated to the Uniswap V3 pool.
    function getTokenBuyQuote(uint256 tokenOrderSize) public view returns (uint256) {
        if (marketType == MarketType.UNISWAP_POOL) revert MarketAlreadyGraduated();

        return bondingCurve.getTokenBuyQuote(totalSupply(), tokenOrderSize);
    }

    /// @notice The amount of ETH that can be received for selling a given number of tokens.
    ///         This will revert if the market has graduated to the Uniswap V3 pool.
    function getTokenSellQuote(uint256 tokenOrderSize) public view returns (uint256) {
        if (marketType == MarketType.UNISWAP_POOL) revert MarketAlreadyGraduated();

        return bondingCurve.getTokenSellQuote(totalSupply(), tokenOrderSize);
    }

    /// @notice The current exchange rate of the token if the market has not graduated.
    ///         This will revert if the market has graduated to the Uniswap V3 pool.
    function currentExchangeRate() public view returns (uint256) {
        if (marketType == MarketType.UNISWAP_POOL) revert MarketAlreadyGraduated();

        uint256 remainingTokenLiquidity = balanceOf(address(this));
        uint256 ethBalance = address(this).balance;

        if (ethBalance < 0.01 ether) {
            ethBalance = 0.01 ether;
        }

        return (remainingTokenLiquidity * 1e18) / ethBalance;
    }


    /// @notice Receives ETH and executes a buy order.
    receive() external payable {
      

        buy(msg.sender, msg.sender, marketType, 0);
    }

 

    /// @dev No-op to allow a swap on the pool to set the correct initial price, if needed
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {}

    /// @dev Overrides ERC20's _update function toPRIMARY_MARKET_SUPPLY
    ///      - Prevent transfers to the pool if the market has not graduated.
    ///      - Emit the superset `WowTokenTransfer` event with each ERC20 transfer.
    function _update(address from, address to, uint256 value) internal virtual override {
        // if (marketType == MarketType.BONDING_CURVE && to == poolAddress) revert MarketNotGraduated();

        super._update(from, to, value);

        emit WowTokenTransfer(from, to, value, balanceOf(from), balanceOf(to), totalSupply());
    }

    /// @dev Validates a bonding curve buy order and if necessary, recalculates the order data if the size is greater than the remaining supply
    function _validateBondingCurveBuy(
        uint256 minOrderSize
    ) internal returns (uint256 totalCost, uint256 trueOrderSize, uint256 fee, uint256 refund, bool startMarket) {
        // Set the total cost to the amount of ETH sent
        totalCost = msg.value;

        // Calculate the fee
        fee = _calculateFee(totalCost, TOTAL_FEE_BPS);

        // Calculate the amount of ETH remaining for the order
        uint256 remainingEth = totalCost - fee;

        // Get quote for the number of tokens that can be bought with the amount of ETH remaining
        trueOrderSize = bondingCurve.getEthBuyQuote(totalSupply(), remainingEth);

        // Ensure the order size is greater than the minimum order size
        if (trueOrderSize < minOrderSize) revert SlippageBoundsExceeded();

        // Calculate the maximum number of tokens that can be bought
        uint256 maxRemainingTokens = PRIMARY_MARKET_SUPPLY - totalSupply();

        // Start the market if the order size equals the number of remaining tokens
        if (trueOrderSize == maxRemainingTokens) {
            startMarket = true;
        }

        // If the order size is greater than the maximum number of remaining tokens:
        if (trueOrderSize > maxRemainingTokens) {
            // Reset the order size to the number of remaining tokens
            trueOrderSize = maxRemainingTokens;

            // Calculate the amount of ETH needed to buy the remaining tokens
            uint256 ethNeeded = bondingCurve.getTokenBuyQuote(totalSupply(), trueOrderSize);

            // Recalculate the fee with the updated order size
            fee = _calculateFee(ethNeeded, TOTAL_FEE_BPS);

            // Recalculate the total cost with the updated order size and fee
            totalCost = ethNeeded + fee;

            // Refund any excess ETH
            if (msg.value > totalCost) {
                refund = msg.value - totalCost;
            }

            startMarket = true;
        }
    }

    /// @dev Handles a bonding curve sell order
    function _handleBondingCurveSell(uint256 tokensToSell, uint256 minPayoutSize) private returns (uint256) {
        // Get quote for the number of ETH that can be received for the number of tokens to sell
        uint256 payout = bondingCurve.getTokenSellQuote(totalSupply(), tokensToSell);

        // Ensure the payout is greater than the minimum payout size
        if (payout < minPayoutSize) revert SlippageBoundsExceeded();

        // Ensure the payout is greater than the minimum order size
        if (payout < MIN_ORDER_SIZE) revert EthAmountTooSmall();

        // Burn the tokens from the seller
        _burn(msg.sender, tokensToSell);

        return payout;
    }


    function getEstimatedTokenAmount(uint ethAmount)
        public
        view
        returns (uint tokenAmount)
    {
        

        // Define the swap path: ETH -> Token
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH(); // WETH address
        path[1] = address(this); // ERC20 token address

        // Get estimated output
        uint[] memory amounts = uniswapV2Router.getAmountsOut(ethAmount, path);

        // Return the token amount (last in the path)
        return amounts[1];
    }

    // Function to swap ETH for ERC20 tokens
    function swapEthForToken(
        uint amountOutMin
    ) external payable {
        require(msg.value > 0, "You need to send some ETH");
       

        // Define the swap path: ETH -> Token
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH(); // WETH address
        path[1] = address(this); // ERC20 token address

        // Perform the swap
        uniswapV2Router.swapExactETHForTokens{value: msg.value}(
            amountOutMin, // Minimum amount of tokens to receive
            path,         // Conversion path
            msg.sender,   // Recipient of tokens
            block.timestamp     // Deadline for the transaction
        );
    }

    function getEstimatedEthAmount(uint tokenAmount)
        public
        view
        returns (uint ethAmount)
    {
      

        address[] memory path = new address[](2);
        path[0] = address(this); // ERC20 token address
        path[1] = uniswapV2Router.WETH(); // WETH address

        // Get estimated output
        uint[] memory amounts = uniswapV2Router.getAmountsOut(tokenAmount, path);

        // Return the ETH amount (last in the path)
        return amounts[1];
    }

    // Function to swap ERC20 tokens for ETH
    function swapTokenForEth(
        uint tokenAmount,
        uint amountOutMin
    ) external {
       require(tokenAmount > 0, "Token amount must be greater than 0");

       transferFrom(msg.sender, address(this), tokenAmount);

        // Approve the router to spend the tokens
     
       _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Define the swap path: Token -> ETH
        address[] memory path = new address[](2);
        path[0] = address(this); // ERC20 token address
        path[1] = uniswapV2Router.WETH(); // WETH address

        // Perform the swap
        uniswapV2Router.swapExactTokensForETH(
            tokenAmount,   // Amount of tokens to swap
            amountOutMin,  // Minimum amount of ETH to receive
            path,          // Conversion path
            msg.sender,    // Recipient of ETH
            block.timestamp       // Deadline for the transaction
        );
    }

    function _graduateMarket() private {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24);
       
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

     
        uniswapV2Router = _uniswapV2Router;
        uint256 ethAmount = address(this).balance;
        _mint(address(this), SECONDARY_MARKET_SUPPLY);

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), SECONDARY_MARKET_SUPPLY);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            SECONDARY_MARKET_SUPPLY,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );
    }