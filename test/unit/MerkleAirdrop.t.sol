// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { MerkleAirdrop } from "../../src/MerkleAirdrop.sol";
import { VineToken } from "../../src/VineToken.sol";
import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { DeployMerkleAirdrop } from "../../script/DeployMerkleAirdrop.s.sol";
import { ZkSyncChainChecker } from "foundry-devops/src/ZkSyncChainChecker.sol";

contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    MerkleAirdrop airdrop;
    VineToken token;
    address gasPayer;
    address user;
    uint256 userPrivKey;

    bytes32 MERKLE_ROOT = 0x126ccdb40064d7906f7b2b9e4eee01b53c087dfe50e2802fa5e472ad5dd76d9d;
    uint256 AMOUNT_TO_CLAIM = (25 * 1e18); // 25.000000
    uint256 AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;

    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0x6a84d1e7c87bd2cdcd308e977d8488be0e0922d5ceb026dce7a1c36a98819de0;
    bytes32[] proof = [proofOne, proofTwo];

    function setUp() public {
        if (!isZkSyncChain()) {
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (airdrop, token) = deployer.deployMerkleAirdrop();
        } else {
            token = new VineToken();
            airdrop = new MerkleAirdrop(MERKLE_ROOT, token);
            token.mint(token.owner(), AMOUNT_TO_SEND);
            token.transfer(address(airdrop), AMOUNT_TO_SEND);
        }
        gasPayer = makeAddr("gasPayer");
        (user, userPrivKey) = makeAddrAndKey("user");
    }

    function signMessage(uint256 privKey, address account) public view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 hashedMessage = airdrop.getMessageHash(account, AMOUNT_TO_CLAIM);
        (v, r, s) = vm.sign(privKey, hashedMessage);
    }

    function testUsersCanClaim() public {
        uint256 startingBalance = token.balanceOf(user);

        // get the signature
        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivKey, user);
        vm.stopPrank();

        // gasPayer claims the airdrop for the user
        vm.prank(gasPayer);
        airdrop.claim(user, AMOUNT_TO_CLAIM, proof, v, r, s);
        uint256 endingBalance = token.balanceOf(user);
        console.log("Ending balance: %d", endingBalance);
        assertEq(endingBalance - startingBalance, AMOUNT_TO_CLAIM);
    }
}
