// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { MerkleAirdrop, IERC20 } from "../src/MerkleAirdrop.sol";
import { Script } from "forge-std/Script.sol";
import { VineToken } from "../src/VineToken.sol";
import { console } from "forge-std/console.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 public ROOT = 0x126ccdb40064d7906f7b2b9e4eee01b53c087dfe50e2802fa5e472ad5dd76d9d;
    // 4 users, 25 vine tokens each
    uint256 public AMOUNT_TO_TRANSFER = 4 * (25 * 1e18);

    // Deploy the airdrop contract and vine token contract
    function deployMerkleAirdrop() public returns (MerkleAirdrop, VineToken) {
        vm.startBroadcast();
        VineToken vineToken = new VineToken();
        MerkleAirdrop airdrop = new MerkleAirdrop(ROOT, IERC20(vineToken));
        // Send Vine tokens -> Merkle Air Drop contract
        vineToken.mint(vineToken.owner(), AMOUNT_TO_TRANSFER);
        IERC20(vineToken).transfer(address(airdrop), AMOUNT_TO_TRANSFER);
        vm.stopBroadcast();
        return (airdrop, vineToken);
    }

    function run() external returns (MerkleAirdrop, VineToken) {
        return deployMerkleAirdrop();
    }
}
