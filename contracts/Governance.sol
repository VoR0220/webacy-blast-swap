// SPDX-License-Identifier: GPL2.0

pragma solidity =0.7.6;

pragma abicoder v2;

import "./interfaces/IBlastInterface.sol";
import './interfaces/IUniswapV3Pool.sol';

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library PoolAddress {
	// TODO: must redo this to make sure that the code hash actually lines up
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

interface ISwapRouter {
	struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

contract Governor {

	uint16 thresholdRiskScore;
	address swapRouter;
	bytes32 public merkleRoot;
	uint totalYieldAccumulated;
	address owner;
	address factory; // pool factory

	constructor(bytes32 _merkleRoot, address _swapRouter, address _factory) {
		merkleRoot = _merkleRoot;
		swapRouter = _swapRouter;
		factory = _factory;
		owner = msg.sender;
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
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
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
        uint amountOut = ISwapRouter(swapRouter).exactInputSingle(params);
		require(amountOut >= 0, "didn't receive anything");

		totalYieldAccumulated -= fee;
		IERC20(tokenOut).transferFrom(address(this), msg.sender, amountOut + fee);

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