// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

/* --------------------------------- IMPORTS -------------------------------- */
import {ERC20} from "./UniswapV2ERC20.sol";
import {SafeTransferLib} from "../lib/solady/src/utils/SafeTransferLib.sol";

/* -------------------------------------------------------------------------- */
/*                                  CONTRACT                                  */
/* -------------------------------------------------------------------------- */

/**
 * @title UniswapV2Pair
 * @author Tathagat Gupta
 * @notice 
 */
contract UniswapV2Pair is UniswapV2ERC20{

/* --------------------------------- ERRORS --------------------------------- */
    error UniswapV2Pair__InvalidAmountDemanded();
    error UniswapV2Pair__NotEnoughLiquidityAvailable();
    error UniswapV2Pair__InvalidAddress();

/* ----------------------------- STATE VARIABLES ---------------------------- */

    uint256 private reserve0; //private variables retrieved using getter functions. 
    uint256 private reserve1; // Can later be used by user of the portocol to access the latest data pf the reserves.
    uint256 private lastBlockTimeStamp;

    address public token0;
    address public token1;

/* ------------------------------- CONSTRUCTOR ------------------------------ */
    constructor(address _token0, address _token1, uint256 _lastBlockTimeStamp){
        token0 = _token0;
        token1 = _token1;
    }

/* ---------------------------- PUBLIC & EXTERNAL FUNCTIONS ---------------------------- */
/**
 * 
 * @param amount0Out Take out amount0Out from the liquidity pool of token0
 * @param amount1Out Take out amount1Out from the liquidity pool of token1
 * @param to This is the address to send the tokens to.
 * @notice Transferring of tokens in UniswapV2 orignal was done with _safeTransfer function.
 *  This function checked checked if there is no return value or return values is a garbage value(USDT).
 *  I am using Solady's safeTransferLib which checks for the aabove and also memory extension attacks,
 *  it is also gas optimized.
 */
    function swap(uint amount0Out, uint amount1Out, address to) public {
        if(amount0Out<0 || amount1Out<0 ){
            revert UniswapV2Pair__InvalidAmountDemanded();
        }
        if(amount0Out==0 && amount1Out==0){
            revert UniswapV2Pair__InvalidAmountDemanded();
        }

        (uint256 _reserve0, uint256 _reserve1) = getReserves();
        if(amount0Out>reserve0 || amount1Out>reserve1){
            revert UniswapV2Pair__NotEnoughLiquidityAvailable();
        }

        address _token0 = token0; //only read the token addresses state once.
        address _token1 = token1;
        if(to == _token0 || to == _token1){
            revert UniswapV2Pair__InvalidAddress();
        }
        SafeTransferLib.safetransfer(token0, to, amount0Out);
        SafeTransferLib.safetransfer(token1, to, amount1Out);

    }

/* -------------------------- VIEW & PURE FUNCTIONS ------------------------- */
    function getReserves() public returns(uint256 _reserve0, uint256 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        lastBlockTimeStamp = _lastBlockTimeStamp;
    }

}