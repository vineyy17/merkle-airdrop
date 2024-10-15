#!/bin/bash

# Define constants
DEFAULT_ZKSYNC_LOCAL_KEY="0x7726827caac94a7f9e1b160f7ea819f172f7b6f9d2a97f992c38edeab82d4110"
DEFAULT_ANVIL_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEFAULT_ZKSYNC_ADDRESS="0x36615Cf349d7F6344891B1e7CA7C72883F5dc049"
DEFAULT_ANVIL_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

ROOT="0x126ccdb40064d7906f7b2b9e4eee01b53c087dfe50e2802fa5e472ad5dd76d9d"
PROOF_1="0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad"
PROOF_2="0x6a84d1e7c87bd2cdcd308e977d8488be0e0922d5ceb026dce7a1c36a98819de0"


# Compile and deploy VineToken contract
echo "Creating zkSync local node..."
npx zksync-cli dev start
echo "Deploying token contract..."
TOKEN_ADDRESS=$(forge create src/VineToken.sol:VineToken --rpc-url http://127.0.0.1:8011 --private-key ${DEFAULT_ZKSYNC_LOCAL_KEY} --legacy --zksync | awk '/Deployed to:/ {print $3}' )
echo "Token contract deployed at: $TOKEN_ADDRESS"

# Deploy MerkleAirdrop contract
echo "Deploying MerkleAirdrop contract..."
AIRDROP_ADDRESS=$(forge create src/MerkleAirdrop.sol:MerkleAirdrop --rpc-url http://127.0.0.1:8011 --private-key ${DEFAULT_ZKSYNC_LOCAL_KEY} --constructor-args ${ROOT} ${TOKEN_ADDRESS} --legacy --zksync | awk '/Deployed to:/ {print $3}' )
echo "MerkleAirdrop contract deployed at: $AIRDROP_ADDRESS"

# Get message hash
MESSAGE_HASH=$(cast call ${AIRDROP_ADDRESS} "getMessageHash(address,uint256)" ${DEFAULT_ANVIL_ADDRESS} 25000000000000000000 --rpc-url http://127.0.0.1:8011)

# Sign message
echo "Signing message..."
SIGNATURE=$(cast wallet sign --private-key ${DEFAULT_ANVIL_KEY} --no-hash ${MESSAGE_HASH})
CLEAN_SIGNATURE=$(echo "$SIGNATURE" | sed 's/^0x//')
echo -n "$CLEAN_SIGNATURE" >> signature.txt

# Split signature 
SIGN_OUTPUT=$(forge script script/SplitSignature.s.sol:SplitSignature)

V=$(echo "$SIGN_OUTPUT" | grep -A 1 "v value:" | tail -n 1 | xargs)
R=$(echo "$SIGN_OUTPUT" | grep -A 1 "r value:" | tail -n 1 | xargs)
S=$(echo "$SIGN_OUTPUT" | grep -A 1 "s value:" | tail -n 1 | xargs)

# Execute remaining steps
echo "Sending tokens to the token contract owner..."
cast send ${TOKEN_ADDRESS} 'mint(address,uint256)' ${DEFAULT_ZKSYNC_ADDRESS} 100000000000000000000 --private-key ${DEFAULT_ZKSYNC_LOCAL_KEY} --rpc-url http://127.0.0.1:8011 > /dev/null
echo "Sending tokens to the airdrop contract..."
cast send ${TOKEN_ADDRESS} 'transfer(address,uint256)' ${AIRDROP_ADDRESS} 100000000000000000000 --private-key ${DEFAULT_ZKSYNC_LOCAL_KEY} --rpc-url http://127.0.0.1:8011 > /dev/null
echo "Claiming tokens on behalf of 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266..."
cast send ${AIRDROP_ADDRESS} 'claim(address,uint256,bytes32[],uint8,bytes32,bytes32)' ${DEFAULT_ANVIL_ADDRESS} 25000000000000000000 "[${PROOF_1},${PROOF_2}]" ${V} ${R} ${S} --private-key ${DEFAULT_ZKSYNC_LOCAL_KEY} --rpc-url http://127.0.0.1:8011 > /dev/null

HEX_BALANCE=$(cast call ${TOKEN_ADDRESS} 'balanceOf(address)' ${DEFAULT_ANVIL_ADDRESS} --rpc-url http://127.0.0.1:8011)

echo "Balance of the claiming address (0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266): $(cast --to-dec ${HEX_BALANCE})"

# Clean up
rm signature.txt