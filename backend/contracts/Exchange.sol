// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    address public tokenAddress;

    // Exchange inherits ERC-20 as it itself is an ERC-20 contract
    // as it is responsible for minitng and issuing LP Tokens
    constructor(address token) ERC20("ETH TOKEN LP TOKEN", "$lpETHTOKEN") {
        require(token != address(0), "Token address passed is a null address");
        tokenAddress = token;
    } 

    /// @dev addLiquidity allows users to add liquidity to the exchange
    /// @return Returns the amount of LP tokens to mint
    function addLiquidity(uint amountOfToken)
        external
        payable
        returns (uint)
    {
        uint lpTokensToMint;
        uint ethReserveBalance = address(this).balance;
        uint tokenReserveBalance = getReserve();

        ERC20 token = ERC20(tokenAddress);

        // if the reserve is empty, take any user supplied value 
        // for inital liquidity
        if (tokenReserveBalance == 0) {
            // transfer the token from the user to the exchange
            token.transferFrom(msg.sender, address(this), amountOfToken);

            // lpTokensToMint = ethReserveBalance = msg.value
            lpTokensToMint = ethReserveBalance;

            // mint LP tokens to the user
            _mint(msg.sender, lpTokensToMint);

            return lpTokensToMint;
        } 

        uint ethReservePriorToFunctionCall = ethReserveBalance - msg.value;
        uint minTokenAmountRequired = (msg.value * tokenReserveBalance) / ethReservePriorToFunctionCall;
        
        require(
            amountOfToken >= minTokenAmountRequired,
            "insufficient amount of tokens provided"
        );

        // transfer the tokens from the user to the exchange
        token.transferFrom(msg.sender, address(this), minTokenAmountRequired);
        
        // calculate the amount of LP tokens to be minted
        lpTokensToMint = (totalSupply() * msg.value) / ethReservePriorToFunctionCall;
        
        // mint LP tokens to the user
        _mint(msg.sender, lpTokensToMint);
        
        return lpTokensToMint;
    }

    /**
     * @dev removeLiquidity allows users to remove liquidity from the exchange
     * @param amountOfLPTokens - amount of LP tokens user wants to burn to get back ETH and TOKEN
     * @return Returns the amount to ETH and tokens to be returned to the user 
     */ 
    function removeLiquidity(uint amountOfLPTokens) external returns (uint, uint) {
        require(
            amountOfLPTokens > 0,
            "Amount of tokens to remove must be greater than 0"
        );

        uint ethReserveBalance = address(this).balance;
        uint lpTokenTotalSupply = totalSupply();

        // calculate the amount of ETH and TOKEN to reutrn to user
        uint ethToReturn = (ethReserveBalance * amountOfLPTokens) / lpTokenTotalSupply;
        uint tokenToReturn = (getReserve() * amountOfLPTokens) / lpTokenTotalSupply;

        // burn the LP tokens from the user,
        // and tranfer the ETH and tokens to the user
        _burn(msg.sender, amountOfLPTokens);
        payable(msg.sender).transfer(ethToReturn);
        ERC20(tokenAddress).transfer(msg.sender, tokenToReturn);

        return (ethToReturn, tokenToReturn);
    }

    function ethToTokenSwap(uint minTokensToReceive) external payable {
        uint tokenReserveBalance = getReserve();
        uint tokensToReceive = getOutputAmountFromSwap(
            msg.value,
            address(this).balance - msg.value,
            tokenReserveBalance
        );

        require(
            tokensToReceive >= minTokensToReceive,
            "Tokens received are less than minimum tokens expected"
        );

        ERC20(tokenAddress).transfer(msg.sender, tokensToReceive);
    }

    function tokenToEthSwap(uint256 tokensToSwap, uint256 minEthToReceive) public {
        uint256 tokenReserveBalance = getReserve();
        uint256 ethToReceive = getOutputAmountFromSwap(
            tokensToSwap,
            tokenReserveBalance,
            address(this).balance
        );

        require(
            ethToReceive >= minEthToReceive,
            "ETH received is less than minimum ETH expected"
        );

        ERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            tokensToSwap
        );

        payable(msg.sender).transfer(ethToReceive);
    }

    /**
     * @dev getOutputAmountFromSwap calcluates the amount of output tokens
     * received based on xy = (x + dx)(y - dy)
     * @param inputAmount - amount of tokens given to be swapped
     * @param inputReserve - reserve of token given to be swapped
     * @param outputReserve - reserve of token that is to be given
     * @return Returns amount of token2 to be received
     */
    function getOutputAmountFromSwap(
        uint inputAmount,
        uint inputReserve,
        uint outputReserve
    ) public pure returns (uint) {
        require(
            inputReserve > 0 && outputReserve > 0,
            "Reserves must be greater than 0"
        );

        uint inputAmountWithFee = inputAmount * 99;

        uint numerator = inputAmountWithFee * outputReserve;
        uint denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;
    }

    /// @dev getReserve returns the balanace of 'token' held by this contract
    function getReserve() public view returns (uint) {
        return ERC20(tokenAddress).balanceOf(address(this));
    }
    
}