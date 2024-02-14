// SPDX-License-Identifier: GPL2.0

pragma solidity =0.7.6;

import "./interfaces/IBlastInterface.sol";
import './interfaces/IUniswapV3Pool.sol';

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

interface ISwapRouter {
    function exactInputSingle(
        exactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

contract Governor {

	uint16 thresholdRiskScore;
	bytes32 public merkleRoot;
	uint totalYieldAccumulated;

	constructor(bytes32 _merkleRoot) {
		merkleRoot = _merkleRoot;
	}

    function isOverThreshold(address addr, uint16 score, uint16 threshold, bytes32[] calldata merkleProof) external view returns (bool) {
        if (score <= threshold) {
            return false;
        }

        // Generate the leaf node by hashing the address and score
        bytes32 leaf = keccak256(abi.encodePacked(addr, score));

        // Verify the proof
        if (!verify(merkleProof, merkleRoot, leaf)) {
            return false;
        }

        return true;
    }

    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash current hash and next proof element
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash next proof element and current hash
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    function swapExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint24 fee
    ) external {

        // Transfer the specified amount of tokenIn to this contract.
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // Approve the router to spend tokenIn.
        IERC20(tokenIn).approve(address(swapRouter), amountIn);

		IUniswapV3Pool pool = getPool(tokenIn, tokenOut, fee);

		uint yieldAmounts = IBlast(0x4300000000000000000000000000000000000002).claimAllYield(address(pool), address(this));
        totalYieldAccumulated += yieldAmounts;

		// Set the parameters for the swap.
        ISwapRouter.exactInputSingleParams memory params = ISwapRouter.exactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0
        });

        // Execute the swap.
        uint amountOut = swapRouter.exactInputSingle(params);
		require(amountOut >= 0, "didn't receive anything");

		totalYieldAccumulated -= fee;
		ERC20(tokenOut).transferFrom(address(this), msg.sender, amountOut + fee);

    }

/// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (IUniswapV3Pool) {
        return IUniswapV3Pool(PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee)));
    }
}