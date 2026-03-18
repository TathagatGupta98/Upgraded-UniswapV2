// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {ERC20} from "../lib/solady/src/tokens/ERC20.sol";


contract UniswapV2ERC20 is ERC20{

    //no contructor arguments as override/virtual costs less gas than reading from storage

    function name() public pure override returns (string memory) {
        return "Uniswap V2";
    }
    function symbol() public pure override returns (string memory) {
        return "UNI-V2";
    }
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    //rest functions like transfer, approve, allowance need no change.
    //_mint and _burn functions will be inherited in UniswapV2Pair contract.
    //permit function will be used by the router. It has full EIP2612 implementation
    
}