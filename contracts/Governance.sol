// SPDX-License-Identifier: GPL2.0

pragma solidity =0.7.6;

contract Governor {

	uint16 thresholdRiskScore;
	bytes32 public merkleRoot;

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
}