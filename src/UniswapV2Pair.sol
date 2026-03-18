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
import {UniswapV2ERC20} from "./UniswapV2ERC20.sol";
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
    error UniswapV2Pair__InvalidInputAmount();
    error UniswapV2Pair__InvalidAMMProduct();
    error UniswapV2__Overflow();

/* ----------------------------- STATE VARIABLES ---------------------------- */

    uint256 private reserve0; //private variables retrieved using getter functions. 
    uint256 private reserve1; // Can later be used by user of the portocol to access the latest data pf the reserves.
    uint256 private blockTimeStampLast;

    address public token0;
    address public token1;

/* --------------------------------- EVENTS --------------------------------- */
    event Swap(
        address indexed sender,
        uint balance0,
        uint balance1,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

/* ------------------------------- CONSTRUCTOR ------------------------------ */
    constructor(address _token0, address _token1, uint256 _blockTimeStampLast){
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
 * @notice The swap function does not transfer tokens from your account on its own. 
 * It later checks if the amountIn were deposited to the reserve has increased by that amount.
 */
    function swap(uint256 amount0Out, uint256 amount1Out, address to) public {
        if(amount0Out==0 && amount1Out==0){
            revert UniswapV2Pair__InvalidAmountDemanded();
        }

        (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimeStampLast) = getReserves();
        if(amount0Out>_reserve0 || amount1Out>_reserve1){
            revert UniswapV2Pair__NotEnoughLiquidityAvailable();
        }

        uint256 balance0;
        uint256 balance1;

        address _token0 = token0; //only read the token addresses state once.
        address _token1 = token1;
        if(to == _token0 || to == _token1){
            revert UniswapV2Pair__InvalidAddress();
        }
        SafeTransferLib.safeTransfer(token0, to, amount0Out);
        SafeTransferLib.safeTransfer(token1, to, amount1Out);

        balance0 = SafeTransferLib.balanceOf(token0, address(this));
        balance1 = SafeTransferLib.balanceOf(token1, address(this));

        verifySwap(balance0, balance1, _reserve0, _reserve1, amount0Out, amount1Out);

        emit Swap(msg.sender, balance0, balance1, amount0Out, amount1Out, to);
    }

    function update(uint256 balance0, uint256 balance1, uint256 _reserve0, uint256 _reserve1) private {

        reserve0 = balance0;
        reserve1 = balance1;

        unchecked {
            uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;

            if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
                price0CumulativeLast += (_reserve1 * 2 ** 112 / _reserve0) * timeElapsed;
                price1CumulativeLast += (_reserve0 * 2 ** 112 / _reserve1) * timeElapsed;
            }

            blockTimestampLast = blockTimestamp;
        }

        emit Sync(reserve0, reserve1);
    }



/* -------------------------- VIEW & PURE FUNCTIONS ------------------------- */
    function verifySwap(uint256 balance0,uint256 balance1, uint256 _reserve0, uint256 _reserve1, uint256 amount0Out,uint256 amount1Out) private pure {

        uint256 amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out)
            : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out
            ? balance1 - (_reserve1 - amount1Out)
            : 0;

        if (amount0In == 0 && amount1In == 0) {
            revert UniswapV2Pair__InvalidInputAmount();
        }

        uint256 balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
        uint256 balance1Adjusted = (balance1 * 1000) - (amount1In * 3);

        if (balance0Adjusted * balance1Adjusted < _reserve0 * _reserve1 * 1_000_000) {
            revert UniswapV2Pair__InvalidAMMProduct();
        }
    }

    function getReserves() public returns(uint256 _reserve0, uint256 _reserve1, uint256 _blockTimeStampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        blockTimeStampLast = _blockTimeStampLast;
    }

}